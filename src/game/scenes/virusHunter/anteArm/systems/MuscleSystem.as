package game.scenes.virusHunter.anteArm.systems
{
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Audio;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.data.sound.SoundModifier;
	import game.scenes.virusHunter.anteArm.components.Muscle;
	import game.scenes.virusHunter.anteArm.components.MuscleHit;
	import game.scenes.virusHunter.anteArm.nodes.MuscleNode;
	import game.systems.SystemPriorities;
	
	public class MuscleSystem extends System
	{
		public function MuscleSystem( )// scene:Scene, events:VirusHunterEvents )
			{
				super._defaultPriority = SystemPriorities.update;
			//	_scene = scene;
			//	_events = events;
			}
			
			override public function addToEngine( systemsManager:Engine ):void
			{
				_nodes = systemsManager.getNodeList( MuscleNode );
			}
			
			override public function update( time:Number ):void
			{
				var node:MuscleNode;
							
				for ( node = _nodes.head; node; node = node.next )
				{					
					if( !node.muscle.init )
					{
						init( node );
					}
				}
			}
			
			private function init( node:MuscleNode ):void
			{
				var muscle:Muscle = node.muscle;
				var entity:Entity = node.entity;
	
				entity.add( new Tween() );
				
				var number:int; 
				
				for( number = 0; number < muscle.acid.length; number ++ )
				{
					var acidEntity:Entity = muscle.acid[ number ];
					
					acidEntity.add( new Tween() );
				}
				
				for( number = 0; number < muscle.hits.length; number ++ )
				{
					var hitEntity:Entity = muscle.hits[ number ];
				
					hitEntity.add( new Tween() );
				}
				
				expandTween( node );
				muscle.init = true;
			}
			
			private function expandTween( node:MuscleNode ):void
			{
				var entity:Entity = node.entity;
				var muscle:Muscle = node.muscle;
				var tween:Tween = entity.get( Tween );
				var spatial:Spatial = entity.get( Spatial );
				
				var number:int; 
				var hit:MuscleHit;
					
				var sound:String = MUSCLE_EXPAND;
				var audio:Audio = entity.get(Audio);
				
				if( audio == null )
				{
					audio = new Audio();
					
					entity.add(audio);
				}
				
				audio.play( SoundManager.EFFECTS_PATH + sound, false, SoundModifier.POSITION );
				
				if( node.muscle.axis == "x" )
				{
					tween.to( spatial, muscle.time, { scaleX : node.muscle.maxExpansion, onComplete : Command.create( constrictTween, node )});
				}
				else
				{
					tween.to( spatial, muscle.time, { scaleY : node.muscle.maxExpansion, onComplete : Command.create( constrictTween, node )});
				}

				// acid
				for( number = 0; number < node.muscle.acid.length; number ++ )
				{
					entity = node.muscle.acid[ number ];
					hit = entity.get( MuscleHit );
					spatial = entity.get( Spatial );
				
					tween = entity.get( Tween );
					tween.to( spatial, muscle.time, { x : hit.endX, y : hit.endY }); //scaleX : hit.endScale,
				}

				// muscle
				for( number = 0; number < node.muscle.hits.length; number ++ )
				{
					entity = node.muscle.hits[ number ];
					hit = entity.get( MuscleHit );
					spatial = entity.get( Spatial );
				
					tween = entity.get( Tween );
					tween.to( spatial, muscle.time, { scaleX : hit.endScale,  x : hit.endX, y : hit.endY, rotation : hit.endRotation });
				}
			}
			
			private function constrictTween( node ):void
			{
				var entity:Entity = node.entity;
				var muscle:Muscle = node.muscle;
				var tween:Tween = entity.get( Tween );
				var spatial:Spatial = entity.get( Spatial );
			
				var number:int;
				
				var sound:String = MUSCLE_CONTRACT;
				var audio:Audio = entity.get(Audio);
				
				if( audio == null )
				{
					audio = new Audio();
					
					entity.add(audio);
				}
				
				audio.play( SoundManager.EFFECTS_PATH + sound, false, SoundModifier.POSITION );
				
				if( node.muscle.axis == "x" )
				{
					tween.to( spatial, muscle.time, { scaleX : 1, onComplete : Command.create( expandTween, node )});
				}
				else
				{
					tween.to( spatial, muscle.time, { scaleY : 1, onComplete : Command.create( expandTween, node )});
				}
				
				// acid
				for( number = 0; number < node.muscle.acid.length; number ++ )
				{
					var acidEntity:Entity = node.muscle.acid[ number ];
					var acidHit:MuscleHit = acidEntity.get( MuscleHit );
					var acidSpatial:Spatial = acidEntity.get( Spatial );
					
					tween = acidEntity.get( Tween );
					tween.to( acidSpatial, muscle.time, { x : acidHit.startX, y : acidHit.startY }); // scaleX : acidHit.startScale, rotation : acidHit.startRotation,
				}
				
				// muscle
				for( number = 0; number < node.muscle.hits.length; number ++ )
				{
					var hitEntity:Entity = node.muscle.hits[ number ];
					var hit:MuscleHit = hitEntity.get( MuscleHit );
				
					var hitSpatial:Spatial = hitEntity.get( Spatial );
				
				
					tween = hitEntity.get( Tween );
					tween.to( hitSpatial, muscle.time, { scaleX : hit.startScale, rotation : hit.startRotation, x : hit.startX, y : hit.startY });
				}	
			}
			
			/*********************************************************************************
			 * UTILS
			 */
			override public function removeFromEngine( systemsManager:Engine ):void
			{
				systemsManager.releaseNodeList( MuscleNode );
				_nodes = null;
			}
			
			private function getMuscleNumber(id:String):String
			{
				return( id.slice( 9, id.length ));
			}
			
		//	private var _scene:Scene;
			//private var _events:VirusHunterEvents;
			private var _nodes:NodeList;
			static private const MUSCLE_EXPAND:String = "contract_expand_muscle_02.mp3";
			static private const MUSCLE_CONTRACT:String = "contract_expand_muscle_01.mp3";
	}
}