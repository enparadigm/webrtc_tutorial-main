import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

typedef void StreamStateCallback(MediaStream stream);

class Signaling {
  Map<String, dynamic> configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302'
        ]
      }
    ]
  };

  RTCPeerConnection? peerConnection;
  RTCDataChannelInit? _dataChannelDict;
  RTCDataChannel? _dataChannel;
  MediaStream? localStream;
  MediaStream? remoteStream;
  String? roomId;
  String? currentRoomText;
  StreamStateCallback? onAddRemoteStream;

  Future<String> createRoom(RTCVideoRenderer remoteRenderer) async {
    // Step 1 - Create Local stream
    peerConnection = await createPeerConnection(configuration);
    registerPeerConnectionListeners();
    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });
    // STEP 1.1.1 - Create Data Channel
    _dataChannelDict = RTCDataChannelInit();
    _dataChannelDict!.ordered = true;
    print('******** SURYA - Line in 35 ******');
    print(_dataChannelDict == null);
    await peerConnection!.createDataChannel(
      "chat",
      RTCDataChannelInit(),
    ).then((value) {
      print('******** SURYA - Data channel Succeed ******');
      _dataChannel = value;
    }).onError((error, stackTrace) {
      print('******** SURYA - Data channel Failed ******');
      print(error);
      print(stackTrace);
    });
    print('Surya in line 45');
    _dataChannel!.onMessage = (RTCDataChannelMessage message) {
      print('Received message: ${message.text}');
    };
    print('Surya in line 49');
    _dataChannel!.onDataChannelState = _onDataChannelState;

    print('Surya - createRoom 32');

    print('Surya - createRoom 38');

    // Step 5 - Collect ICE candidates
    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      print('****SURYA Got candidate *********');
      print('Surya - Got candidate: ${candidate.toMap()}');
      print('****SURYA Got candidate *********');
      // peerConnection!.addCandidate(
      //   RTCIceCandidate(
      //     data['candidate'],
      //     data['sdpMid'],
      //     data['sdpMLineIndex'],
      //   ),
      // );
    };
    // Step 1.1 - Create offer
     await peerConnection!.createOffer().then((pyOffer) async {
       await peerConnection!.setLocalDescription(pyOffer);
       print('Surya - Created offer: ${pyOffer.toMap()}');
       print('***** Surya Checking ICE Is complete ******');
       _waitForGatheringComplete().then((value){
         // Step 2 - Post Created offer to the local hosted API
         postData(offer: pyOffer.toMap(), onSuccess: (answer) async {
           // Step 3 - Get the answer type as a response
           //todo - Get the response
           print("Surya - API Call Succeed");
           print('**** SDP *********');
           print(answer['sdp']);
           print('**** TYPE *********');
           print(answer['type']);
           // Step 4 - Use the answer response and set it to remote peer
           final remoteAnswer =  RTCSessionDescription(
             answer['sdp'],
             answer['type'],
           );
           await peerConnection?.setRemoteDescription(remoteAnswer).then((value){
             print('****SURYA REMOTE SET SUCCESSFULLY *********');

             Future.delayed(Duration(seconds: 4),(){
               print('*** SURYA SENDING MESSAGE AS start_recording');
               sendMessage('start_recording');
               Future.delayed(Duration(seconds: 4),(){
                 print('*** SURYA SENDING MESSAGE AS STOP_RECORDING');
                 sendMessage('stop_recording');
               });
             });


           }).onError((error, stackTrace) {
             print('**** SURYA FAILed TO SET REMOTE *********');
             print(error);
             print(stackTrace);
           });


           // Step 6 - Listen for remote repose
           peerConnection?.onTrack = (RTCTrackEvent event) {
             print('Surya - Got remote track: ${event.streams[0]}');

             event.streams[0].getTracks().forEach((track) {
               print('Surya - Add a track to the remoteStream $track');
               remoteStream?.addTrack(track);
             });
           };
         }, onFailure: (){
           print("Surya - API Call failed");
         });
       });
     }).onError((error, stackTrace) {
       print('Surya - Failed to create offer');
       print(error);
       print(stackTrace);
     });

    // // Step 4 - Use the answer response and set it to remote peer
    // await peerConnection?.setRemoteDescription(answer);
    // Step 5 - Collect ICE candidates
    // var callerCandidatesCollection = roomRef.collection('callerCandidates');
    // peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
    //   print('Surya - Got candidate: ${candidate.toMap()}');
    //   // callerCandidatesCollection.add(candidate.toMap());
    //   peerConnection!.addCandidate(
    //     RTCIceCandidate(
    //       data['candidate'],
    //       data['sdpMid'],
    //       data['sdpMLineIndex'],
    //     ),
    //   );
    // };
    // peerConnection!.addCandidate(
    //   RTCIceCandidate(
    //     data['candidate'],
    //     data['sdpMid'],
    //     data['sdpMLineIndex'],
    //   ),
    // );
    // Step 6 - Listen for remote repose
    // peerConnection?.onTrack = (RTCTrackEvent event) {
    //   print('Surya - Got remote track: ${event.streams[0]}');
    //
    //   event.streams[0].getTracks().forEach((track) {
    //     print('Surya - Add a track to the remoteStream $track');
    //     remoteStream?.addTrack(track);
    //   });
    // };
    //
    // // Data Channel
    // // Step 1 - Step data channel for
    // FirebaseFirestore db = FirebaseFirestore.instance;
    // DocumentReference roomRef = db.collection('rooms').doc();
    //
    // print('Surya - Create PeerConnection with configuration: $configuration');
    //
    // peerConnection = await createPeerConnection(configuration);
    //
    // registerPeerConnectionListeners();
    //
    // localStream?.getTracks().forEach((track) {
    //   peerConnection?.addTrack(track, localStream!);
    // });
    //
    // // Code for collecting ICE candidates below
    // var callerCandidatesCollection = roomRef.collection('callerCandidates');
    //
    // peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
    //   print('Surya - Got candidate: ${candidate.toMap()}');
    //   callerCandidatesCollection.add(candidate.toMap());
    // };
    // // Finish Code for collecting ICE candidate
    //
    // // Add code for creating a room
    // RTCSessionDescription offer = await peerConnection!.createOffer();
    // await peerConnection!.setLocalDescription(offer);
    // print('Surya - Created offer: $offer');
    //
    // Map<String, dynamic> roomWithOffer = {'offer': offer.toMap()};
    //
    // await roomRef.set(roomWithOffer);
    // var roomId = roomRef.id;
    // print('Surya - New room created with SDK offer. Room ID: $roomId');
    // currentRoomText = 'Current room is $roomId - You are the caller!';
    // // Created a Room
    //
    // peerConnection?.onTrack = (RTCTrackEvent event) {
    //   print('Surya - Got remote track: ${event.streams[0]}');
    //
    //   event.streams[0].getTracks().forEach((track) {
    //     print('Surya - Add a track to the remoteStream $track');
    //     remoteStream?.addTrack(track);
    //   });
    // };
    //
    // // Listening for remote session description below
    // roomRef.snapshots().listen((snapshot) async {
    //   print('Surya - Got updated room: ${snapshot.data()}');
    //
    //   Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    //   if (peerConnection?.getRemoteDescription() != null &&
    //       data['answer'] != null) {
    //     var answer = RTCSessionDescription(
    //       data['answer']['sdp'],
    //       data['answer']['type'],
    //     );
    //
    //     print("Surya - Someone tried to connect");
    //     await peerConnection?.setRemoteDescription(answer);
    //   }
    // });
    // // Listening for remote session description above
    //
    // // Listen for remote Ice candidates below
    // roomRef.collection('calleeCandidates').snapshots().listen((snapshot) {
    //   snapshot.docChanges.forEach((change) {
    //     if (change.type == DocumentChangeType.added) {
    //       Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
    //       print('Surya - Got new remote ICE candidate: ${jsonEncode(data)}');
    //       peerConnection!.addCandidate(
    //         RTCIceCandidate(
    //           data['candidate'],
    //           data['sdpMid'],
    //           data['sdpMLineIndex'],
    //         ),
    //       );
    //     }
    //   });
    // });
    // Listen for remote ICE candidates above

    return "roomId";
  }

  Future<void> joinRoom(String roomId, RTCVideoRenderer remoteVideo) async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    print(roomId);
    DocumentReference roomRef = db.collection('rooms').doc('$roomId');
    var roomSnapshot = await roomRef.get();
    print('Surya - Got room ${roomSnapshot.exists}');

    if (roomSnapshot.exists) {
      print('Surya - Create PeerConnection with configuration: $configuration');
      peerConnection = await createPeerConnection(configuration);

      registerPeerConnectionListeners();

      localStream?.getTracks().forEach((track) {
        peerConnection?.addTrack(track, localStream!);
      });

      // Code for collecting ICE candidates below
      var calleeCandidatesCollection = roomRef.collection('calleeCandidates');
      peerConnection!.onIceCandidate = (RTCIceCandidate? candidate) {
        if (candidate == null) {
          print('Surya - onIceCandidate: complete!');
          return;
        }
        print('Surya - Details of callee - onIceCandidate: ${candidate.toMap()}');
        calleeCandidatesCollection.add(candidate.toMap());
      };
      // Code for collecting ICE candidate above

      peerConnection?.onTrack = (RTCTrackEvent event) {
        print('Surya - Got remote track: ${event.streams[0]}');
        event.streams[0].getTracks().forEach((track) {
          print('Surya - Add a track to the remoteStream: $track');
          remoteStream?.addTrack(track);
        });
      };

      // Code for creating SDP answer below
      var data = roomSnapshot.data() as Map<String, dynamic>;
      print('Surya - Got offer $data');
      var offer = data['offer'];
      await peerConnection?.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']),
      );
      var answer = await peerConnection!.createAnswer();
      print('Surya - Created Answer $answer');

      await peerConnection!.setLocalDescription(answer);

      Map<String, dynamic> roomWithAnswer = {
        'answer': {'type': answer.type, 'sdp': answer.sdp}
      };

      await roomRef.update(roomWithAnswer);
      // Finished creating SDP answer

      // Listening for remote ICE candidates below
      roomRef.collection('callerCandidates').snapshots().listen((snapshot) {
        snapshot.docChanges.forEach((document) {
          var data = document.doc.data() as Map<String, dynamic>;
          print(data);
          print('Surya - Got new remote ICE candidate: $data');
          peerConnection!.addCandidate(
            RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            ),
          );
        });
      });
    } else {
      print('Surya - Room doest exists');
    }
  }

  Future<void> openUserMedia(
    RTCVideoRenderer localVideo,
    RTCVideoRenderer remoteVideo,
  ) async {
    var stream = await navigator.mediaDevices
        .getUserMedia({'video': true, 'audio': true});

    localVideo.srcObject = stream;
    localStream = stream;

    remoteVideo.srcObject = await createLocalMediaStream('key');
  }

  Future<void> hangUp(RTCVideoRenderer localVideo) async {
    List<MediaStreamTrack> tracks = localVideo.srcObject!.getTracks();
    tracks.forEach((track) {
      track.stop();
    });

    if (remoteStream != null) {
      remoteStream!.getTracks().forEach((track) => track.stop());
    }
    if (peerConnection != null) peerConnection!.close();

    if (roomId != null) {
      var db = FirebaseFirestore.instance;
      var roomRef = db.collection('rooms').doc(roomId);
      var calleeCandidates = await roomRef.collection('calleeCandidates').get();
      calleeCandidates.docs.forEach((document) => document.reference.delete());

      var callerCandidates = await roomRef.collection('callerCandidates').get();
      callerCandidates.docs.forEach((document) => document.reference.delete());

      await roomRef.delete();
    }

    localStream!.dispose();
    remoteStream?.dispose();
  }

  void registerPeerConnectionListeners() {
    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      print('Surya -Listener ICE gathering state changed: $state');
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      print('Surya -Listener Connection state change: $state');
    };

    peerConnection?.onSignalingState = (RTCSignalingState state) {
      print('Surya -Listener Signaling state change: $state');
    };

    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      print('Surya -Listener ICE connection state change: $state');
    };

    peerConnection?.onAddStream = (MediaStream stream) {
      print("Surya - Listener Add remote stream");
      onAddRemoteStream?.call(stream);
      remoteStream = stream;
    };

  }

  // check ICEgathering is complete or not
  Future<bool> _waitForGatheringComplete() async {
    print("WAITING FOR GATHERING COMPLETE");
    if (peerConnection!.iceGatheringState ==
        RTCIceGatheringState.RTCIceGatheringStateComplete) {
      print('***** Surya - ICE is COMPLETE ******');
      return true;
    } else {
      print('***** Surya - ICE is NOT COMPLETE ******');
      await Future.delayed(Duration(seconds: 1));
      return await _waitForGatheringComplete();
    }
  }

  // Data Channel
  void sendMessage(String message) {
    if (_dataChannel != null && _dataChannel!.state == RTCDataChannelState.RTCDataChannelOpen) {
      print('*** SURYA - Data channel sending the meesage - $message');
      _dataChannel!.send(RTCDataChannelMessage(message));
    } else {
      print('*** SURYA - Data channel is not open');
    }
  }
  void _onDataChannelState(RTCDataChannelState? state) {
    switch (state) {
      case RTCDataChannelState.RTCDataChannelClosed:
        print("Camera Closed!!!!!!!");
        break;
      case RTCDataChannelState.RTCDataChannelOpen:
        print("Camera Opened!!!!!!!");
        break;
      default:
        print("Data Channel State: $state");
    }
  }
}



Future<void> postData({required Map<String, dynamic> offer,required Function(Map<String, dynamic>) onSuccess,required Function onFailure,}) async {
  final String url = 'http://localhost:8080/offer';

  // Prepare the request body
  Map<String, dynamic> body = offer;

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        // Add any additional headers if required
        // 'Authorization': 'Bearer YOUR_TOKEN',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      // Request successful
      print('Response: ${response.body}');
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      onSuccess(jsonResponse);
      // Parse the response JSON if needed
      // final responseData = jsonDecode(response.body);
    } else {
      // Request failed
      print('Request failed with status: ${response.statusCode}');
      onFailure();
    }
  } catch (e) {
    // Handle any errors that occurred during the request
    print('Error: $e');
  }
}