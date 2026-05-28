import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mina_app/auth/ApiService.dart';
import 'package:mina_app/provider/user_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class VideoCallPage extends StatefulWidget {
  final Object appointmentId;
  final String? accessToken;
  final String title;

  const VideoCallPage({
    super.key,
    required this.appointmentId,
    this.accessToken,
    this.title = 'Video Call',
  });

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  final ApiService _api = ApiService();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final List<String> _events = [];

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  bool _connecting = true;
  bool _micEnabled = true;
  bool _cameraEnabled = true;
  bool _offerSent = false;
  bool _remoteDescriptionSet = false;
  bool _allowPop = false;
  String? _error;
  Uri? _websocketUri;
  int? _currentUserId;
  final List<RTCIceCandidate> _pendingIceCandidates = [];

  bool get _isDoctor {
    final role = Provider.of<UserProvider>(context, listen: false).role;
    return role.toLowerCase() == 'doctor';
  }

  @override
  void initState() {
    super.initState();
    _initCall();
  }

  Future<void> _initCall() async {
    try {
      _currentUserId = Provider.of<UserProvider>(context, listen: false).userId;
      _log('Starting video call, userId=$_currentUserId, isDoctor=$_isDoctor');

      await _localRenderer.initialize();
      await _remoteRenderer.initialize();
      _log('Renderers initialized');

      await _requestPermissions();
      await _openLocalMedia();
      await _createPeerConnection();
      await _connectSignaling();
    } catch (e, stack) {
      _log('Initialization error: $e\n$stack');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _connecting = false;
        });
      }
    }
  }

  Future<void> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();
    await Permission.bluetoothConnect.request();

    if (cameraStatus.isPermanentlyDenied || micStatus.isPermanentlyDenied) {
      await openAppSettings();
      throw Exception('Permissions permanently denied. Please enable in settings.');
    }

    if (!cameraStatus.isGranted || !micStatus.isGranted) {
      throw Exception('Camera and microphone are required for video calls.');
    }
    _log('Permissions granted');
  }

  Future<void> _openLocalMedia() async {
    try {
      final stream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {
          'facingMode': 'user',
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
        },
      });
      _localStream = stream;
      _localRenderer.srcObject = stream;
      _log('Local stream acquired, tracks: ${stream.getTracks().map((t) => t.kind).toList()}');
    } catch (e) {
      _log('getUserMedia failed: $e');
      rethrow;
    }
  }

  Future<void> _createPeerConnection() async {
    _log('Creating RTCPeerConnection with Unified Plan');

    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
        {'urls': 'stun:stun2.l.google.com:19302'},
        {'urls': 'stun:stun3.l.google.com:19302'},
        {'urls': 'stun:stun4.l.google.com:19302'},
      ],
      'sdpSemantics': 'unified-plan',
    };

    final pc = await createPeerConnection(configuration);

    pc.onIceConnectionState = (state) {
      _log('ICE connection state: $state');
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected) {
        _log('✅ ICE connected');
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        _log('❌ ICE failed - check STUN/TURN servers');
      }
    };

    pc.onIceGatheringState = (state) {
      _log('ICE gathering state: $state');
    };

    pc.onConnectionState = (state) {
      _log('PeerConnection state: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _log('✅ WebRTC connection established');
      }
    };

    // SIMPLE onTrack handler – no fancy stream creation, just use what's provided
    pc.onTrack = (event) {
      _log('Remote track received: ${event.track.kind}, id=${event.track.id}');
      if (event.streams.isNotEmpty) {
        final remoteStream = event.streams.first;
        _log('Remote stream has ${remoteStream.getTracks().length} tracks');
        setState(() {
          _remoteRenderer.srcObject = remoteStream;
        });
      } else {
        _log('No stream attached to track – waiting');
      }
    };

    pc.onIceCandidate = (candidate) {
      if (candidate.candidate != null && candidate.candidate!.isNotEmpty) {
        _log('Local ICE candidate generated, sending');
        _sendSignal('ice-candidate', candidate.toMap());
      }
    };

    // Add local tracks: audio first, then video (Android requirement)
    final audioTracks = _localStream?.getAudioTracks() ?? [];
    final videoTracks = _localStream?.getVideoTracks() ?? [];

    for (final track in audioTracks) {
      await pc.addTrack(track, _localStream!);
      _log('Added audio track');
    }
    for (final track in videoTracks) {
      await pc.addTrack(track, _localStream!);
      _log('Added video track');
    }

    _peerConnection = pc;
  }

  Future<void> _connectSignaling() async {
    await _subscription?.cancel();
    await _channel?.sink.close();
    _subscription = null;
    _channel = null;

    setState(() {
      _connecting = true;
      _error = null;
    });

    final connection = await _api.startVideoCall(
      widget.appointmentId,
      accessToken: widget.accessToken,
    );
    _channel = connection.channel;
    _websocketUri = connection.websocketUri;
    _log('Connected to signaling server: ${_websocketUri?.host}');

    _subscription = connection.channel.stream.listen(
      (message) async {
        _log('Raw signal received: $message');
        await _handleSignalMessage(message);
      },
      onError: (error) {
        _log('Signaling error: $error');
        if (mounted) setState(() => _error = error.toString());
      },
      onDone: () {
        _log('Signaling connection closed');
      },
    );

    if (mounted) setState(() => _connecting = false);
    await Future.delayed(const Duration(milliseconds: 500));

    if (_isDoctor) {
      _log('Doctor: creating and sending offer');
      await _createAndSendOffer();
    } else {
      _log('Patient: waiting for doctor offer');
      _sendSignal('ready', {
        'appointment_id': widget.appointmentId.toString(),
      });
    }
  }

  Future<void> _createAndSendOffer({bool force = false}) async {
    final pc = _peerConnection;
    if (pc == null || (_offerSent && !force)) return;

    _log('Creating offer...');
    final offer = await pc.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': true,
    });
    await pc.setLocalDescription(offer);
    _sendSignal('offer', offer.toMap());
    _offerSent = true;
    _log('Offer sent');
  }

  Future<void> _handleSignalMessage(dynamic message) async {
    Map<String, dynamic>? payload;
    try {
      final decoded = message is String ? jsonDecode(message) : message;
      if (decoded is Map) payload = Map<String, dynamic>.from(decoded);
    } catch (_) {
      _log('Non-JSON message received: $message');
      return;
    }

    if (payload == null) return;
    var type = payload['type']?.toString();
    var data = payload['data'];

    if (type == 'video_signal' && data is Map) {
      final signal = Map<String, dynamic>.from(data);
      final fromUser = signal['from_user'];
      if (_currentUserId != null && fromUser?.toString() == _currentUserId.toString()) {
        _log('Ignoring own signal');
        return;
      }
      type = signal['signal_type']?.toString();
      data = signal['signal_data'];
    }

    _log('Signal type: $type');
    switch (type) {
      case 'offer':
        await _handleOffer(data);
        break;
      case 'answer':
        await _handleAnswer(data);
        break;
      case 'ice-candidate':
      case 'ice_candidate':
      case 'candidate':
        await _handleIceCandidate(data);
        break;
      case 'ready':
      case 'participant_joined':
      case 'user_joined':
      case 'joined':
        if (_isDoctor) {
          _log('Patient is ready; sending offer');
          await _createAndSendOffer(force: true);
        }
        break;
      default:
        _log('Unhandled signal type: $type');
    }
  }

  Future<void> _handleOffer(dynamic data) async {
    if (_isDoctor && _offerSent) {
      _log('Ignoring echoed offer (doctor already sent)');
      return;
    }

    final pc = _peerConnection;
    if (pc == null) return;

    final description = _descriptionFrom(data, fallbackType: 'offer');
    if (description == null) {
      _log('Failed to parse offer SDP');
      return;
    }

    _log('Setting remote description (offer)');
    await pc.setRemoteDescription(description);
    _remoteDescriptionSet = true;
    await _flushPendingIceCandidates();

    _log('Creating answer');
    final answer = await pc.createAnswer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': true,
    });
    await pc.setLocalDescription(answer);
    _sendSignal('answer', answer.toMap());
    _log('Answer sent');
  }

  Future<void> _handleAnswer(dynamic data) async {
    final pc = _peerConnection;
    if (pc == null) return;

    final description = _descriptionFrom(data, fallbackType: 'answer');
    if (description == null) {
      _log('Failed to parse answer SDP');
      return;
    }

    _log('Setting remote description (answer)');
    await pc.setRemoteDescription(description);
    _remoteDescriptionSet = true;
    await _flushPendingIceCandidates();
    _log('Answer applied');
  }

  Future<void> _handleIceCandidate(dynamic data) async {
    final pc = _peerConnection;
    if (pc == null) return;

    final candidate = _candidateFrom(data);
    if (candidate == null) {
      _log('Invalid ICE candidate received');
      return;
    }

    _log('ICE candidate received');
    if (!_remoteDescriptionSet) {
      _log('Queueing ICE candidate (remote description pending)');
      _pendingIceCandidates.add(candidate);
      return;
    }

    await pc.addCandidate(candidate);
    _log('ICE candidate added');
  }

  Future<void> _flushPendingIceCandidates() async {
    final pc = _peerConnection;
    if (pc == null || _pendingIceCandidates.isEmpty) return;
    _log('Flushing ${_pendingIceCandidates.length} pending ICE candidates');
    final candidates = List<RTCIceCandidate>.from(_pendingIceCandidates);
    _pendingIceCandidates.clear();
    for (final candidate in candidates) {
      await pc.addCandidate(candidate);
    }
  }

  RTCSessionDescription? _descriptionFrom(dynamic data, {required String fallbackType}) {
    if (data is String) {
      return RTCSessionDescription(data, fallbackType);
    }
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final sdp = map['sdp']?.toString() ?? map['description']?.toString();
      final type = map['type']?.toString() ?? fallbackType;
      if (sdp == null || sdp.isEmpty) return null;
      return RTCSessionDescription(sdp, type);
    }
    return null;
  }

  RTCIceCandidate? _candidateFrom(dynamic data) {
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);
    final candidate = map['candidate']?.toString();
    if (candidate == null || candidate.isEmpty) return null;
    final sdpMLineIndexValue = map['sdpMLineIndex'];
    return RTCIceCandidate(
      candidate,
      map['sdpMid']?.toString(),
      sdpMLineIndexValue is int
          ? sdpMLineIndexValue
          : int.tryParse(sdpMLineIndexValue?.toString() ?? ''),
    );
  }

  void _sendSignal(String type, dynamic data) {
    final channel = _channel;
    if (channel == null) {
      _log('Cannot send $type – signaling channel not open');
      return;
    }
    final payload = jsonEncode({'type': type, 'data': data});
    _log('Sending signal: $type');
    channel.sink.add(payload);
  }

  void _toggleMic() {
    final audioTracks = _localStream?.getAudioTracks() ?? [];
    setState(() => _micEnabled = !_micEnabled);
    for (final track in audioTracks) {
      track.enabled = _micEnabled;
    }
    _log('Mic toggled: ${_micEnabled ? "ON" : "OFF"}');
  }

  void _toggleCamera() {
    final videoTracks = _localStream?.getVideoTracks() ?? [];
    setState(() => _cameraEnabled = !_cameraEnabled);
    for (final track in videoTracks) {
      track.enabled = _cameraEnabled;
    }
    _log('Camera toggled: ${_cameraEnabled ? "ON" : "OFF"}');
  }

  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    print('[$timestamp] $message');
    if (mounted) {
      setState(() {
        _events.insert(0, message);
        if (_events.length > 30) _events.removeLast();
      });
    }
  }

  Future<void> _endCall() async {
    _log('Ending call');
    await _subscription?.cancel();
    await _channel?.sink.close();
    await _peerConnection?.close();
    _localStream?.getTracks().forEach((track) => track.stop());
    _localRenderer.srcObject = null;
    _remoteRenderer.srcObject = null;
    if (mounted) {
      setState(() => _allowPop = true);
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop,
      child: Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(widget.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _remoteRenderer.srcObject == null
                  ? _CallStatus(
                      connecting: _connecting,
                      error: _error,
                      host: _websocketUri?.host,
                      isDoctor: _isDoctor,
                    )
                  : RTCVideoView(
                      _remoteRenderer,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
            ),
            Positioned(
              top: 16,
              right: 16,
              width: 120,
              height: 170,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: RTCVideoView(
                    _localRenderer,
                    mirror: true,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 88,
              child: _events.isEmpty
                  ? const SizedBox.shrink()
                  : Text(
                      _events.first,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _RoundCallButton(
                    icon: _micEnabled ? Icons.mic : Icons.mic_off,
                    onPressed: _toggleMic,
                  ),
                  _RoundCallButton(
                    icon: Icons.call_end,
                    backgroundColor: Colors.red,
                    onPressed: _endCall,
                  ),
                  _RoundCallButton(
                    icon: _cameraEnabled ? Icons.videocam : Icons.videocam_off,
                    onPressed: _toggleCamera,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  @override
  void dispose() {
    _log('Disposing video call resources');
    _subscription?.cancel();
    _channel?.sink.close();
    _peerConnection?.close();
    _localStream?.getTracks().forEach((track) => track.stop());
    _localRenderer.srcObject = null;
    _remoteRenderer.srcObject = null;
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }
}

class _CallStatus extends StatelessWidget {
  final bool connecting;
  final String? error;
  final String? host;
  final bool isDoctor;

  const _CallStatus({
    required this.connecting,
    required this.error,
    required this.host,
    required this.isDoctor,
  });

  @override
  Widget build(BuildContext context) {
    if (connecting) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              error == null ? Icons.videocam : Icons.error_outline,
              color: Colors.white,
              size: 72,
            ),
            const SizedBox(height: 16),
            Text(
              error == null
                  ? (isDoctor ? 'Calling patient...' : 'Waiting for doctor...')
                  : 'Call connection failed',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error ?? host ?? 'mina-backend-1.onrender.com',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundCallButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color backgroundColor;

  const _RoundCallButton({
    required this.icon,
    required this.onPressed,
    this.backgroundColor = const Color(0xFF374151),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 58,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
        ),
        child: Icon(icon),
      ),
    );
  }
}
