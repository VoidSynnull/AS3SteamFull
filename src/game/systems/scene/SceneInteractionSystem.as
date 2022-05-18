package game.systems.scene
{
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.character.Character;
	import game.components.entity.character.CharacterWander;
	import game.components.motion.Destination;
	import game.components.motion.MotionControlBase;
	import game.components.scene.SceneInteraction;
	import game.nodes.scene.SceneInteractionNode;
	import game.util.CharUtils;
	import game.util.MotionUtils;
	
	import org.osflash.signals.Signal;
	
	public class SceneInteractionSystem extends System
	{
		public function SceneInteractionSystem()
		{
			
		}
		
		override public function addToEngine(gameSystems:Engine):void
		{
			_nodes = gameSystems.getNodeList(SceneInteractionNode);
			
			_nodes.nodeAdded.add(nodeAdded);
			_nodes.nodeRemoved.add(nodeRemoved);
			
			var node:SceneInteractionNode;
			
			for( node = _nodes.head; node; node = node.next )
			{
				nodeAdded(node);
			}
		}
		
		override public function removeFromEngine(gameSystems:Engine) : void
		{
			gameSystems.releaseNodeList(SceneInteractionNode);
			_nodes = null;
		}
		
		private function nodeAdded(node:SceneInteractionNode):void
		{
			if(node.interaction.up != null)
			{
				node.interaction.up.add(interactionTriggered);
			}
			else if(node.interaction.down != null)
			{
				node.interaction.down.add(interactionTriggered);
			}
			else if(node.interaction.click != null)
			{
				node.interaction.click.add(interactionTriggered);
			}
			
			if(node.sceneInteraction.reached == null)
			{
				node.sceneInteraction.reached = new Signal(Entity, Entity);
			}
			
			if(node.sceneInteraction.triggered == null)
			{
				node.sceneInteraction.triggered = new Signal(Entity, Entity);
			}
		}
		
		private function interactionTriggered(entity:Entity):void
		{
			var sceneInteraction:SceneInteraction = entity.get(SceneInteraction);
			if(sceneInteraction != null)
				sceneInteraction.activated = true;
		}
		
		private function nodeRemoved(node:SceneInteractionNode):void
		{
			node.sceneInteraction.reached.removeAll();
			node.sceneInteraction.triggered.removeAll();
		}
		
		override public function update(time:Number):void
		{
			for(var node:SceneInteractionNode = _nodes.head; node; node = node.next)
			{
				var sceneInteraction:SceneInteraction = node.sceneInteraction;
				if( sceneInteraction.activated && !sceneInteraction.disabled)
				{
					sceneInteraction.activated = false;
					
					var interactor:Entity = super.group.getEntityById(sceneInteraction.interactorID);	// entity that is interacting with entity owning SceneInteracvtion
					sceneInteraction.triggered.dispatch(interactor, node.entity);
					
					if( interactor != null && sceneInteraction.approach)
					{
						var spatial:Spatial = node.entity.get(Spatial);
						var dialog:Dialog = node.entity.get(Dialog);
						var interactorSpatial:Spatial = interactor.get(Spatial);
						
						// add offsets to target
						sceneInteraction.targetX = spatial.x + sceneInteraction.offsetX;	
						sceneInteraction.targetY = spatial.y + sceneInteraction.offsetY;
						
						if(dialog)
						{
							if (interactorSpatial.x < spatial.x || !dialog.faceSpeaker)	// flip offset if entity approaches from other side
							{
								if((!dialog.faceSpeaker && spatial.scaleX > 0) || dialog.faceSpeaker)
								{
									sceneInteraction.targetX = spatial.x - sceneInteraction.offsetX;
								}
							}
							
							dialog.initiated = true;
							var wander:CharacterWander = node.entity.get(CharacterWander);
							if(wander)
							{
								dialog.stoppedToListen = true;
								wander.pause = true;
							}
						}
						else
						{
							if (interactorSpatial.x < spatial.x && sceneInteraction.autoSwitchOffsets)	// flip offset if entity approaches from other side
							{
								sceneInteraction.targetX = spatial.x - sceneInteraction.offsetX;
							}
						}
						
						// set facing target upon reaching target
						var targetDirectionX:Number = spatial.x;
						var targetDirectionY:Number = spatial.y;
						
						// determines if on reaching target, interacting entity faces target or target + offset
						if(sceneInteraction.offsetDirection)	
						{
							targetDirectionX = spatial.x + sceneInteraction.offsetX;
							targetDirectionY = spatial.y + sceneInteraction.offsetX;
						}
						
						// setup moving to target
						var destination:Destination;
						if(interactor.has(Character) && !interactor.has(MotionControlBase))	// if interactor Entity is character, move them with character methods
						{
							destination = CharUtils.moveToTarget(interactor, sceneInteraction.targetX, sceneInteraction.targetY, sceneInteraction.lockInput, null, sceneInteraction.minTargetDelta );
							destination.ignorePlatformTarget = sceneInteraction.ignorePlatformTarget;
							
							if( sceneInteraction.validCharStates != null ){
								destination.validCharStates = sceneInteraction.validCharStates;	// TODO :: need to copy array?
							}
						}
						else
						{
							destination = MotionUtils.moveToTarget(interactor, sceneInteraction.targetX, sceneInteraction.targetY, sceneInteraction.lockInput, null, sceneInteraction.minTargetDelta );
							destination.motionToZero.push( "x" );
							destination.motionToZero.push( "y" );
						}
	
						destination.setDirectionOnReached( sceneInteraction.faceDirection, targetDirectionX, targetDirectionY );
						destination.onFinalReached.addOnce( Command.create(sceneInteraction.reached.dispatch, node.entity ) );
						/*
						// TODO :: Might want to allow sceneInteraction to pass motionToZero itself. In future a Destinationdata class would be ideal. - Bard
						if( sceneInteraction.motionToZero != null && sceneInteraction.motionToZero.length > 0 )
						{
							destination.motionToZero = sceneInteraction.motionToZero.slice();
						}
						*/
						// TODO :: have listener for interrupt?
					}
					/*
					else if(sceneInteraction.follow)
					{
						CharUtils.followEntity(interactor, node.entity);
						// TODO :: Can use destination here as well. -bard
					}
					*/
				}
			}
		}
		
		private var _nodes:NodeList;
	}
}
