import AVFAudio
import CallKit
import Flutter
import PushKit
import UIKit
import flutter_callkit_incoming

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate,
  PKPushRegistryDelegate, CallkitIncomingAppDelegate
{
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Regista para receber pushes VoIP (PushKit) — necessário para o iPhone
    // tocar como chamada a sério (CallKit) mesmo com a app fechada.
    let voipRegistry = PKPushRegistry(queue: DispatchQueue.main)
    voipRegistry.delegate = self
    voipRegistry.desiredPushTypes = [PKPushType.voIP]

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  // MARK: - PushKit (VoIP)

  /// Novo token VoIP do dispositivo → guardado pelo plugin e enviado ao backend
  /// pelo lado Dart (que o lê via getDevicePushTokenVoIP).
  func pushRegistry(
    _ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType
  ) {
    let deviceToken = credentials.token.map { String(format: "%02x", $0) }.joined()
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(deviceToken)
  }

  func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP("")
  }

  /// Chega um push VoIP → mostra imediatamente o CallKit (obrigatório pela Apple
  /// dentro deste handler, senão a app é terminada). Os dados da chamada WebRTC
  /// vão em `extra` para o lado Dart reconstruir ao atender.
  func pushRegistry(
    _ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload,
    for type: PKPushType, completion: @escaping () -> Void
  ) {
    guard type == .voIP else {
      completion()
      return
    }
    let p = payload.dictionaryPayload
    let id = p["room"] as? String ?? (p["id"] as? String ?? UUID().uuidString)
    let nameCaller = p["quem_liga"] as? String ?? "Chamada"
    let handle = p["handle"] as? String ?? "ONDAKA"

    let data = flutter_callkit_incoming.Data(
      id: id, nameCaller: nameCaller, handle: handle, type: 0)
    data.appName = "ONDAKA"
    // Reencaminha todo o payload (room, signaling_url, ice_servers, origem…)
    // para o Dart reconstruir a chamada ao atender.
    data.extra = p as? [String: Any] ?? [:]

    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(data, fromPushKit: true) {
      completion()
    }
  }

  // MARK: - CallkitIncomingAppDelegate (acções da UI nativa)
  // A negociação WebRTC é feita pelo lado Dart (eventos onEvent). Aqui só
  // confirmamos as acções ao sistema.

  func onAccept(_ call: Call, _ action: CXAnswerCallAction) {
    action.fulfill()
  }

  func onDecline(_ call: Call, _ action: CXEndCallAction) {
    action.fulfill()
  }

  func onEnd(_ call: Call, _ action: CXEndCallAction) {
    action.fulfill()
  }

  func onTimeOut(_ call: Call) {}

  func didActivateAudioSession(_ audioSession: AVAudioSession) {}

  func didDeactivateAudioSession(_ audioSession: AVAudioSession) {}
}
