package game.systems.entity.character
{
	import flash.display.DisplayObjectContainer;
	
	import game.nodes.entity.character.CharacterJumpAssistNode;
	import game.nodes.entity.character.JumpTargetIndicatorNode;
	import game.scene.template.PlatformerGameScene;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	public class CharacterJumpAssistSystem extends GameSystem
	{
		private var _jumpIndicatorNode:JumpTargetIndicatorNode;
		
		public function CharacterJumpAssistSystem()
		{
			super(CharacterJumpAssistNode, updateNode );
			
			super._defaultPriority = SystemPriorities.moveControl;
			super.fixedTimestep = 1/60;
		}

		private function updateNode(node:CharacterJumpAssistNode, time:Number):void
		{
			if(_jumpIndicatorNode == null)
			{
				_jumpIndicatorNode = super.systemManager.getNodeList(JumpTargetIndicatorNode).head;
				if( _jumpIndicatorNode != null )
				{
					_jumpIndicatorNode.display.visible = false;
					//node.charMotionControl.allowAutoTarget = true;
					node.charMotionControl.targetJumping = false;
				}
			}

			if(node.charMotionControl.jumpTargetTrigger && _jumpIndicatorNode != null)
			{
				node.charMotionControl.allowAutoTarget = false;
				_jumpIndicatorNode.display.visible = true;
				node.charMotionControl.jumpTargetTrigger = false;
				node.charMotionControl.targetJumping = true;
				var container:DisplayObjectContainer = PlatformerGameScene(super.group).hitContainer;

				_jumpIndicatorNode.timeline.gotoAndPlay("animateIn");
				_jumpIndicatorNode.spatial.x = container.mouseX;
				_jumpIndicatorNode.spatial.y = container.mouseY;
			}
		}
	}
}