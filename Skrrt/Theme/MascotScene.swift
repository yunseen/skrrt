import SceneKit
import SwiftUI
import UIKit

struct MascotScene: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView(frame: .zero)
        view.backgroundColor = .clear
        view.isOpaque = false
        view.antialiasingMode = .multisampling4X
        view.preferredFramesPerSecond = 60
        view.isUserInteractionEnabled = false
        view.autoenablesDefaultLighting = false
        view.scene = context.coordinator.scene
        view.delegate = context.coordinator
        view.rendersContinuously = true
        view.isPlaying = true
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {}

    final class Coordinator: NSObject, SCNSceneRendererDelegate {
        let scene = SCNScene()

        private struct Actor {
            let body: SCNNode
            let shadow: SCNNode
            let shadowScale: Float
        }

        private var actors: [Actor] = []

        override init() {
            super.init()
            build()
        }

        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
            for actor in actors {
                let lift = Float(actor.body.presentation.position.y)
                let factor = max(0.45, 1 - 0.22 * lift)
                actor.shadow.scale = SCNVector3(actor.shadowScale * factor, actor.shadowScale * factor, actor.shadowScale * factor)
                actor.shadow.opacity = CGFloat(max(0.25, 1 - 0.35 * lift))
            }
        }

        private func build() {
            scene.background.contents = UIColor.clear

            let camera = SCNNode()
            camera.camera = SCNCamera()
            camera.camera?.fieldOfView = 34
            camera.camera?.zNear = 0.1
            camera.camera?.zFar = 60
            camera.position = SCNVector3(0, 0, 8)
            scene.rootNode.addChildNode(camera)

            let ambient = SCNNode()
            ambient.light = SCNLight()
            ambient.light?.type = .ambient
            ambient.light?.intensity = 450
            ambient.light?.color = UIColor(red: 0.92, green: 0.92, blue: 1, alpha: 1)
            scene.rootNode.addChildNode(ambient)

            let key = SCNNode()
            key.light = SCNLight()
            key.light?.type = .directional
            key.light?.intensity = 1100
            key.light?.color = UIColor.white
            key.eulerAngles = SCNVector3(-0.8, 0.55, 0)
            scene.rootNode.addChildNode(key)

            let fill = SCNNode()
            fill.light = SCNLight()
            fill.light?.type = .omni
            fill.light?.intensity = 350
            fill.light?.color = UIColor(red: 0.55, green: 0.68, blue: 1, alpha: 1)
            fill.position = SCNVector3(-3, 1.5, 5)
            scene.rootNode.addChildNode(fill)

            scene.lightingEnvironment.contents = UIColor(white: 1, alpha: 1)
            scene.lightingEnvironment.intensity = 0.7

            let shadowImage = Self.shadowImage()
            let layout: [(x: Float, y: Float, z: Float, scale: Float, height: CGFloat, delay: TimeInterval, spins: Bool)] = [
                (-0.10, 0.95, 0, 0.85, 1.05, 0.0, false),
                (0.78, 1.55, -1.0, 0.45, 0.8, 0.7, true),
                (-0.80, 1.45, -0.8, 0.40, 0.9, 1.3, false)
            ]
            for item in layout {
                let root = SCNNode()
                root.position = SCNVector3(item.x, item.y, item.z)
                root.scale = SCNVector3(item.scale, item.scale, item.scale)
                scene.rootNode.addChildNode(root)

                let body = Self.makeMascot()
                root.addChildNode(body)

                let shadow = SCNNode(geometry: SCNPlane(width: 1.3, height: 1.3))
                shadow.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
                shadow.position = SCNVector3(0, -0.82, 0)
                let material = SCNMaterial()
                material.lightingModel = .constant
                material.diffuse.contents = shadowImage
                material.isDoubleSided = true
                material.writesToDepthBuffer = false
                material.blendMode = .alpha
                shadow.geometry?.materials = [material]
                root.addChildNode(shadow)

                body.runAction(Self.jumpLoop(height: item.height, delay: item.delay, spins: item.spins))
                actors.append(Actor(body: body, shadow: shadow, shadowScale: 1))
            }
        }

        private static func material(_ color: UIColor, roughness: CGFloat = 0.55) -> SCNMaterial {
            let material = SCNMaterial()
            material.lightingModel = .physicallyBased
            material.diffuse.contents = color
            material.roughness.contents = roughness
            material.metalness.contents = 0.0
            return material
        }

        private static func part(_ geometry: SCNGeometry, _ color: UIColor, at position: SCNVector3, scale: SCNVector3 = SCNVector3(1, 1, 1), roughness: CGFloat = 0.55) -> SCNNode {
            geometry.materials = [material(color, roughness: roughness)]
            let node = SCNNode(geometry: geometry)
            node.position = position
            node.scale = scale
            return node
        }

        private static func makeMascot() -> SCNNode {
            let purple = UIColor(red: 0.74, green: 0.64, blue: 0.96, alpha: 1)
            let deep = UIColor(red: 0.68, green: 0.58, blue: 0.92, alpha: 1)
            let cream = UIColor(red: 0.99, green: 0.96, blue: 0.88, alpha: 1)
            let ink = UIColor(red: 0.08, green: 0.06, blue: 0.09, alpha: 1)

            let root = SCNNode()
            root.addChildNode(part(SCNCapsule(capRadius: 0.5, height: 1.5), purple, at: SCNVector3(0, 0, 0), scale: SCNVector3(1.05, 1, 0.92)))
            root.addChildNode(part(SCNSphere(radius: 0.42), cream, at: SCNVector3(0, 0.16, 0.40), scale: SCNVector3(1.0, 0.82, 0.30), roughness: 0.7))

            for side: Float in [-1, 1] {
                let eye = part(SCNSphere(radius: 0.075), ink, at: SCNVector3(0.17 * side, 0.18, 0.60), scale: SCNVector3(0.85, 1.2, 0.6), roughness: 0.15)
                let glint = SCNSphere(radius: 0.022)
                let glintMaterial = SCNMaterial()
                glintMaterial.lightingModel = .constant
                glintMaterial.diffuse.contents = UIColor.white
                glint.materials = [glintMaterial]
                let glintNode = SCNNode(geometry: glint)
                glintNode.position = SCNVector3(0.02 * side, 0.05, 0.06)
                eye.addChildNode(glintNode)
                root.addChildNode(eye)
                let closed = squash(from: SCNVector3(0.85, 1.2, 0.6), to: SCNVector3(0.85, 0.12, 0.6), duration: 0.07)
                let open = squash(from: SCNVector3(0.85, 0.12, 0.6), to: SCNVector3(0.85, 1.2, 0.6), duration: 0.09)
                let wait = SCNAction.wait(duration: 2.8, withRange: 1.6)
                eye.runAction(.repeatForever(.sequence([wait, closed, open])))

                root.addChildNode(part(SCNSphere(radius: 0.17), purple, at: SCNVector3(0.56 * side, -0.12, 0.12), scale: SCNVector3(0.8, 1.25, 0.9)))
                root.addChildNode(part(SCNSphere(radius: 0.2), deep, at: SCNVector3(0.26 * side, -0.72, 0.12), scale: SCNVector3(1.0, 0.7, 1.25)))
            }

            root.addChildNode(part(SCNCylinder(radius: 0.035, height: 0.28), purple, at: SCNVector3(0, 0.88, 0)))
            root.addChildNode(part(SCNSphere(radius: 0.11), purple, at: SCNVector3(0, 1.06, 0)))
            return root
        }

        private static func jumpLoop(height: CGFloat, delay: TimeInterval, spins: Bool) -> SCNAction {
            let crouch = SCNAction.group([
                squash(from: SCNVector3(1, 1, 1), to: SCNVector3(1.12, 0.80, 1.12), duration: 0.22),
                .moveBy(x: 0, y: -0.09, z: 0, duration: 0.22)
            ])

            let launch = SCNAction.group([
                .moveBy(x: 0, y: height + 0.09, z: 0, duration: 0.42),
                squash(from: SCNVector3(1.12, 0.80, 1.12), to: SCNVector3(0.93, 1.10, 0.93), duration: 0.2)
            ])

            let fall = SCNAction.group([
                .moveBy(x: 0, y: -height, z: 0, duration: 0.38),
                squash(from: SCNVector3(0.93, 1.10, 0.93), to: SCNVector3(1, 1, 1), duration: 0.38)
            ])

            var air: SCNAction = .sequence([launch, fall])
            if spins {
                air = .group([air, .rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 0.8)])
            }

            let land = squash(from: SCNVector3(1, 1, 1), to: SCNVector3(1.16, 0.76, 1.16), duration: 0.09)
            let recover = squash(from: SCNVector3(1.16, 0.76, 1.16), to: SCNVector3(1, 1, 1), duration: 0.3)
            let rest = SCNAction.wait(duration: 0.55, withRange: 0.5)

            return .sequence([
                .wait(duration: delay),
                .repeatForever(.sequence([crouch, air, land, recover, rest]))
            ])
        }

        /// Smoothly changes a node's scale along each axis (SceneKit has no per-axis scale action).
        private static func squash(from: SCNVector3, to: SCNVector3, duration: TimeInterval) -> SCNAction {
            SCNAction.customAction(duration: duration) { node, elapsed in
                let raw = duration > 0 ? Float(elapsed) / Float(duration) : 1
                let progress = min(max(raw, 0), 1)
                let eased = 1 - (1 - progress) * (1 - progress)
                node.scale = SCNVector3(
                    from.x + (to.x - from.x) * eased,
                    from.y + (to.y - from.y) * eased,
                    from.z + (to.z - from.z) * eased
                )
            }
        }

        private static func shadowImage() -> UIImage {
            let size = CGSize(width: 128, height: 128)
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            format.opaque = false
            return UIGraphicsImageRenderer(size: size, format: format).image { context in
                let colors = [UIColor(white: 0, alpha: 0.45).cgColor, UIColor(white: 0, alpha: 0).cgColor] as CFArray
                guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) else { return }
                let center = CGPoint(x: 64, y: 64)
                context.cgContext.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: 62, options: [])
            }
        }
    }
}
