
package game.scenes.carnival.shared.game3d.nodes {
	
	import ash.core.Node;
	
	import game.scenes.carnival.shared.game3d.components.Spatial3D;
	import game.scenes.carnival.shared.game3d.components.MoveTarget3D;
	import game.scenes.carnival.shared.game3d.components.Motion3D;

	public class MoveTarget3DNode extends Node {

		public var spatial:Spatial3D;
		public var target:MoveTarget3D;

		public var motion:Motion3D;

	} // End MoveTarget3DNode
	
} // End package