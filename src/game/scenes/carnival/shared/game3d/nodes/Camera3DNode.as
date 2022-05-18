package game.scenes.carnival.shared.game3d.nodes {

	import ash.core.Node;

	import engine.components.Display;

	import game.scenes.carnival.shared.game3d.components.Camera3D;
	import game.scenes.carnival.shared.game3d.components.Frustum;

	public class Camera3DNode extends Node {

		public var display:Display;
		public var camera:Camera3D;
		public var frustum:Frustum;

	} // End Camera3DNode
	
} // End package