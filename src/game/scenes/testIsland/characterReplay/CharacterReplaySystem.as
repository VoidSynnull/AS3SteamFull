package game.scenes.testIsland.characterReplay
{
	import flash.utils.getDefinitionByName;
	
	import avmplus.getQualifiedClassName;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.character.animation.RigAnimation;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.CharUtils;
	import game.util.Utils;
	
	public class CharacterReplaySystem extends GameSystem
	{
		public function CharacterReplaySystem()
		{
			super(CharacterReplayNode, updateNode);
			super._defaultPriority = SystemPriorities.update;
		}
		
		private function updateNode(node:CharacterReplayNode, time:Number):void
		{
			var replay:CharacterReplayComponent = node.characterReplay;
			
			if(replay.play)
			{
				var currentState:CharacterSceneState = pickCurrentState(replay.replayTime, replay.states);
				
				replay.replayTime += time;
				
				if(node.current.state == null)
				{
					node.current.previousState = currentState;
					node.spatial.x = currentState.x;
					node.spatial.y = currentState.y;
					node.spatial.rotation = currentState.rotation;
					node.spatial.scaleX = currentState.scaleX;
					node.spatial.scaleY = currentState.scaleY;
					
					currentState = pickCurrentState(replay.replayTime, replay.states);
				}

				if(replay.replayTime >= replay.recordTime)
				{
					currentState = null;
					replay.play = false;
				}
				
				node.current.state = currentState;
			}
			else if(replay.record && replay.source)
			{
				if(replay.states.length == 0 || replay.timeSinceLastSample >= replay.sampleRate)
				{
					if(replay.states.length > 0)
					{
						var previous:CharacterSceneState = replay.states[replay.states.length - 1];
						previous.duration = replay.timeSinceLastSample;
					}
					
					replay.timeSinceLastSample = 0;

					var sourceSpatial:Spatial = replay.source.get(Spatial);
					var sourceMotion:Motion = replay.source.get(Motion);
					var rigAnimation:RigAnimation = CharUtils.getRigAnim(replay.source);
					var animation:Class = getDefinitionByName(getQualifiedClassName(rigAnimation.current)) as Class;
					
					var newState:CharacterSceneState = new CharacterSceneState();
					newState.x = sourceSpatial.x;
					newState.y = sourceSpatial.y;
					newState.scaleX = sourceSpatial.scaleX;
					newState.scaleY = sourceSpatial.scaleY;
					newState.rotation = sourceSpatial.rotation;
					newState.startTime = replay.recordTime;
					newState.animation = animation;
					
					replay.states.push(newState);
					
					if(replay.randomSamples)
					{
						replay.sampleRate = Utils.randNumInRange(.02, 1);
					}
				}
				else
				{
					replay.timeSinceLastSample += time;
				}
				
				replay.recordTime += time;
			}
		}
		
		private function pickCurrentState(time:Number, states:Vector.<CharacterSceneState>):CharacterSceneState
		{
			var previous:CharacterSceneState;
			
			for each(var state:CharacterSceneState in states)
			{
				if(previous == null)
				{
					previous = state;
				}
				else
				{
					if(state.startTime > time)
					{
						return previous;
					}
					
					previous = state;
				}
			}
			
			return previous;
		}
	}
}