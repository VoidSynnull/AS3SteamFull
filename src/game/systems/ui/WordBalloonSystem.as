package game.systems.ui
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Engine;
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.OwningGroup;
	import engine.components.SpatialOffset;
	import engine.group.Group;
	import engine.managers.SoundManager;
	
	import game.components.entity.Dialog;
	import game.components.entity.character.Talk;
	import game.components.motion.Edge;
	import game.data.scene.characterDialog.DialogData;
	import game.nodes.ui.WordBalloonNode;
	import game.systems.GameSystem;
	import game.systems.entity.character.CharacterDialogSystem;
	import game.ui.characterDialog.DialogTriggerDelegate;
	import game.util.DataUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.Utils;
	
	import org.osflash.signals.Signal;

	public class WordBalloonSystem extends GameSystem
	{
		public function WordBalloonSystem()
		{
			super(WordBalloonNode, updateNode, addNode, removeNode); 
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			dialogComplete = new Signal(DialogData);
			
			super.addToEngine(systemManager);
		}
		
		private function addNode( node:WordBalloonNode ) : void
		{		
			if(node.wordBalloon.dialogData.triggerEvent && node.wordBalloon.dialogData.triggerEvent.triggerFirst)
			{
				if( dialogTriggerDelegate )
				{
					dialogTriggerDelegate.handleDialogTriggerEvent(node.wordBalloon.dialogData);
				}
			}
		}
		
		private function removeNode( node:WordBalloonNode ) : void
		{
			node.wordBalloon.removed.removeAll();
			stopTalkAnimation(node);
			var dialog:Dialog = node.parent.parent.get(Dialog);
			
			if(dialog != null)
			{
				dialog.speaking = false;
				var audio:Audio = node.parent.parent.get(Audio);
				if(audio != null && node.groupSpatialOffset == null)//dont stop audio if it is one of the selectable question dialog bubbles
				{
					var url:String = node.wordBalloon.dialogData.audioUrl;
					if(url != null)
						audio.stop(SoundManager.SPEECH_PATH + url);
				}
			}
		}

		private function updateNode(node:WordBalloonNode, time:Number) : void
		{
			if( !node.wordBalloon.dialogData.waitingToStart )
			{
				// just do this once per dialog balloon
				if( !node.wordBalloon.started )
				{
					startDialog( node );
				}
				
				/*
				if(node.entity.sleeping)
				{
					stopTalkAnimation(node);
					super.group.removeEntity(node.entity);
					return;
				}
				*/
				
				this.position(node, time);
				
				if (!isNaN(node.wordBalloon.lifespan))
				{
					if (node.wordBalloon.lifespan > 0)	// decrement lifespan
					{
						if(node.spatial.scaleX != 1)
						{
							if(node.spatial.scaleX < 1)
							{
								node.spatial.scaleX += 8 * time;
								node.spatial.scaleY += 8 * time;
								
								if(node.spatial.scaleX > 1)
								{
									node.spatial.scaleX = 1;
									node.spatial.scaleY = 1;
								}
							}
						}
						
						node.wordBalloon.lifespan -= time;
					}
					else if (node.spatial.scaleX > 0)	// lifespan is up, decrease size of word balloon
					{
						// shrink scale
						node.spatial.scaleX -= 8 * time;		
						node.spatial.scaleY -= 8 * time;
						
						if(node.spatial.scaleX < 0)
						{
							node.spatial.scaleX = 0;
							node.spatial.scaleY = 0;
						}
						
						// end Talk
						stopTalkAnimation(node);
					}
					else	// balloon has reached scale 0
					{						
						if(!node.wordBalloon.suppressEventTrigger)
						{
							if (node.wordBalloon.dialogData.triggerEvent != null && !node.wordBalloon.dialogData.triggerEvent.triggerFirst)
							{
								if( dialogTriggerDelegate )
								{
									dialogTriggerDelegate.handleDialogTriggerEvent(node.wordBalloon.dialogData);
								}
								//triggerEvent.dispatch(node.wordBalloon.dialogData);
							}
							
							dialogComplete.dispatch(node.wordBalloon.dialogData);
						}
					
						if(node.wordBalloon.speak)
						{
							var dialog:Dialog = node.parent.parent.get(Dialog);
							dialog.complete.dispatch(node.wordBalloon.dialogData);
							dialog.speaking = false;
							
							// NOTE :: Shouldn't progress with dialog link if speaking entity is asleep (offscreen)
							if( !node.parent.parent.sleeping && node.wordBalloon.dialogData.link != null )
							{
								if( DataUtils.validString(node.wordBalloon.dialogData.linkEntityId) )
								{
									var owningGroup:Group = node.parent.parent.get(OwningGroup).group;
									var linkEntity:Entity = owningGroup.getEntityById(node.wordBalloon.dialogData.linkEntityId);
									
									if(linkEntity)
									{
										dialog = linkEntity.get(Dialog);
										
										if(dialog == null)
										{
											dialog = node.parent.parent.get(Dialog);
										}
										else
										{
											trace("Error :: WordBalloonSystem :: Linked dialog entity does not have a dialog component.");
										}
									}
									else
									{
										trace("Error :: WordBalloonSystem :: Linked dialog entity does not exist.");
									}
								}
								
								dialog.say(node.wordBalloon.dialogData.link);
							}
						}
						
						node.wordBalloon.removed.dispatch(node.wordBalloon);
						node.wordBalloon.removed.removeAll();
						
						super.systemManager.removeEntity(node.entity);
					}
				}
				// if no dialog text to display, then look for linked dialog for player
				else
				{
					var linkedID:String = node.wordBalloon.dialogData.linkEntityId;
					if (( DataUtils.validString(linkedID) ) && (linkedID == "player"))
					{
						owningGroup = node.parent.parent.get(OwningGroup).group;
						linkEntity = owningGroup.getEntityById(linkedID);
						dialog = linkEntity.get(Dialog);
						dialog.say(node.wordBalloon.dialogData.link);
						
						// remove existing balloon
						node.wordBalloon.removed.dispatch(node.wordBalloon);
						node.wordBalloon.removed.removeAll();
						super.systemManager.removeEntity(node.entity);
					}
				}
			}
		}
		
		private function startDialog( node:WordBalloonNode ) : void
		{
			node.wordBalloon.started = true;
			if(node.wordBalloon.speak)
			{
				// set entity to talk
				// TODO :: This method of accessing Talk isn't very good, would liek a more direct relationship
				var talk:Talk = node.parent.parent.get(Talk);
				if( talk )
				{
					talk.isStart = true;
				}
				// dispatch Dialog's start signal
				var dialog:Dialog = node.parent.parent.get(Dialog);
				dialog.start.dispatch(node.wordBalloon.dialogData);
			}
		}
		
		private function position(node:WordBalloonNode, time:Number):void
		{
			var offset:Point = getBalloonOffset(node.parent.parent);
			//if(target.has(Display) && target.get(Display).displayObject != null)
			
			var display:Display = EntityUtils.getDisplay(node.parent.parent);
			var dialogContainer:DisplayObjectContainer = node.display.container;
			var relative:Point = new Point();
			if(display)
			{
				relative = DisplayUtils.localToLocal(display.container, dialogContainer);
			}
			
			offset = offset.add(relative);
			
			var camera:Rectangle = new Rectangle(0,0,group.shellApi.viewportWidth, group.shellApi.viewportHeight);//popup
			
			if(node.wordBalloon.cameraLimits && !node.wordBalloon.dialogData.forceOnScreen)
			{
				camera = node.wordBalloon.cameraLimits;//scene
			}
			else
			{
				if(node.display.container.name == "uiLayer")
				{
					//view of camera
					camera = new Rectangle(-node.display.container.x * group.shellApi.camera.scale - group.shellApi.viewportWidth / 2, -node.display.container.y * group.shellApi.camera.scale - group.shellApi.viewportHeight / 2, group.shellApi.viewportWidth, group.shellApi.viewportHeight);
				}
			}
			
			var constrainedAxis:String;
			
			if(node.groupSpatialOffset)
			{
				var last:SpatialOffset = node.groupSpatialOffset.offsets[node.groupSpatialOffset.offsets.length - 1];
				var origin:SpatialOffset = node.groupSpatialOffset.offsets[0];
				var difference:Point = new Point(offset.x - origin.x, offset.y - origin.y - CharacterDialogSystem.QUESTION_OFFSET);
				
				constrainedAxis = constrain(node, time, dialogContainer, camera.left, camera.top, camera.right, camera.bottom, new Point(last.x + difference.x, last.y + difference.y), last);
				
				for each (var spatialOffset:SpatialOffset in node.groupSpatialOffset.offsets)
				{
					if(constrainedAxis.indexOf("x") < 0)
						spatialOffset.x += difference.x;
					if(constrainedAxis.indexOf("y") < 0)
						spatialOffset.y += difference.y;
				}
			}
			else
			{
				constrainedAxis = constrain(node, time, dialogContainer, camera.left, camera.top, camera.right, camera.bottom, new Point(offset.x, offset.y));
				if(constrainedAxis.indexOf("x") < 0)
					node.offset.x = offset.x;
				if(constrainedAxis.indexOf("y") < 0)
					node.offset.y = offset.y;
			}
		}
		
		private function getBalloonOffset( target:Entity ):Point
		{
			var offset:Point = new Point();
			var dialog:Dialog = target.get( Dialog );
			var edge:Edge = target.get( Edge );
			if ( dialog && edge )
			{
				if ( dialog.dialogPositionPercents )
				{
					offset.x = edge.rectangle.width * dialog.dialogPositionPercents.x;
					offset.y = edge.rectangle.height * -dialog.dialogPositionPercents.y;
				}
			}
			
			return offset;
		}
		
		private function constrain(node:WordBalloonNode, time:Number, container:DisplayObject, left:Number, top:Number, right:Number, bottom:Number, offset:Point = null, topOffset:SpatialOffset = null):String
		{
			var constrained:String = "";
			var constrainedX:Boolean = false;
			var constrainedY:Boolean = false;
			var ease:Number = Utils.getVariableTimeEase(.2, time);
			var offsetX:Number = 0;
			var offsetY:Number = 0;
			var additionalX:Number = 0;
			var additionalY:Number = 0;
			if(offset)
			{
				additionalX = offset.x - node.offset.x;
				additionalY = offset.y - node.offset.y;
			}
			var bounds:Rectangle = node.display.displayObject.getBounds(container);
			
			if(bounds.left + additionalX < left)
			{
				constrainedX = true;
				offsetX = (left - bounds.left) * ease;
			}
			
			if(bounds.top + additionalY < top)
			{
				constrainedY = true;
				offsetY = (top - bounds.top) * ease;
			}
			
			if(bounds.right + additionalX > right)
			{
				constrainedX = true;
				offsetX = (right - bounds.right) * ease;
			}
			
			if(bounds.bottom + additionalY > bottom)
			{
				constrainedY = true;
				offsetY = (bottom - bounds.bottom) * ease;
			}
			
			if(node.groupSpatialOffset != null)
			{					
				var nextOffset:SpatialOffset;
				
				for(var n:int = 0; n < node.groupSpatialOffset.offsets.length; n++)
				{
					nextOffset = node.groupSpatialOffset.offsets[n];
					nextOffset.x += offsetX;
					if(!topOffset || node.offset == topOffset)
						nextOffset.y += offsetY;
				}
			}
			else
			{
				node.offset.x += offsetX;
				node.offset.y += offsetY;
			}
			
			if(constrainedX)
				constrained+="x";
			if(constrainedY)
				constrained+="y";
			
			return constrained;
		}
		
		private function stopTalkAnimation(node:WordBalloonNode):void
		{
			if(node.wordBalloon.speak)		// flag talk to stop, happens once
			{
				var talk:Talk = node.parent.parent.get(Talk);
				if( talk )
				{
					if( talk._active )
					{
						talk.isEnd = true;
					}
				}
			}
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			if(super.nodeList)
			{
				var node:WordBalloonNode;
				
				for ( node = super.nodeList.head; node; node = node.next )
				{
					if(node.wordBalloon.removed != null)
					{
						node.wordBalloon.removed.removeAll();
					}
				}
			}
			
			dialogTriggerDelegate = null;
			dialogComplete.removeAll();
			systemManager.releaseNodeList( WordBalloonNode );
			
			super.removeFromEngine(systemManager);
		}
		
		public var dialogComplete:Signal;	// TODO :: Would like to get rid of this - bard
		public var dialogTriggerDelegate:DialogTriggerDelegate;
	}
}
