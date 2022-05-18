package game.scenes.testIsland.characterReplay
{
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.CharUtils;
	
	public class CharacterSceneStateSystem extends GameSystem
	{
		public function CharacterSceneStateSystem()
		{
			super(CharacterSceneStateNode, updateNode);
			super._defaultPriority = SystemPriorities.moveControl;
		}
		
		private function updateNode(node:CharacterSceneStateNode, time:Number):void
		{
			var state:CharacterSceneState = node.current.state;
			var previousState:CharacterSceneState = node.current.previousState;
			
			if(state != null && previousState != null)
			{
				if(node.current.invalidate)
				{
					node.current.invalidate = false;
					node.current.timeInState = 0;
					if(state.animation != null)
					{
						CharUtils.setAnim(node.entity, state.animation, false );
					}
				}
				
				node.current.timeInState += time;
				
				var ratio:Number = 0;
				var timeDelta:Number = state.startTime - previousState.startTime;
				
				if(timeDelta != 0)
				{
					ratio = node.current.timeInState / timeDelta;
				}

				ratio = Math.min(1, ratio);
				
				var deltaX:Number = (state.x - previousState.x) * ratio;
				var deltaY:Number = (state.y - previousState.y) * ratio;
				var deltaRotation:Number = (state.rotation - previousState.rotation) * ratio;
				
				node.spatial.scaleX = state.scaleX;
				node.spatial.scaleY = state.scaleY;
				node.spatial.x = previousState.x + deltaX;
				node.spatial.y = previousState.y + deltaY;
				node.spatial.rotation = previousState.rotation + deltaRotation;
			}
		}
	}
}