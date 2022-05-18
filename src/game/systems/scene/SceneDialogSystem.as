package game.systems.scene
{
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.nodes.CameraNode;
	
	import game.components.entity.Dialog;
	import game.components.ui.WordBalloon;
	import game.data.scene.characterDialog.DialogParser;
	import game.nodes.scene.SceneDialogNode;
	import game.nodes.ui.WordBalloonNode;
	import game.systems.GameSystem;
	
	
	public class SceneDialogSystem extends GameSystem
	{
		
		public function SceneDialogSystem()
		{
			super(WordBalloonNode, updateNode, nodeAdded, nodeRemoved);
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			super.addToEngine(systemManager);
			
			_speakerNodes = systemManager.getNodeList(SceneDialogNode);
			_cameraNodes = systemManager.getNodeList(CameraNode);
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			super.removeFromEngine(systemManager);
			
			systemManager.releaseNodeList(SceneDialogNode);
			_speakerNodes = null;
		}
				
		override public function update(time:Number):void
		{
			super.update(time);
			
			if(_zoomChanged)
			{
				_zoomWait -= time;
				
				if(_zoomWait <= 0)
				{
					doZoom();
				}
			}
		}
		
		private function updateNode(node:WordBalloonNode, time:Number):void
		{	
			var wordBalloon:WordBalloon = node.wordBalloon;
			
			// check for speaker to exceed motion threshold, is so remove dialog balloons
			if(!wordBalloon.speak && wordBalloon.lifespan != 0)
			{	
				var speaker:SceneDialogNode = _speakerNodes.head;
				if ( speaker )
				{	
					if(Math.abs(speaker.motion.velocity.x) > SceneDialogSystem.SPEAKER_MAX_VELX)
					{
						if(wordBalloon.dialogData.type == DialogParser.QUESTION)
						{
							wordBalloon.suppressEventTrigger = true;
							wordBalloon.lifespan = 0;
							speaker.dialog.speaking = false;
							speaker.dialog.initiated = false;
							
							if(wordBalloon.answer)
							{
								var npc:Entity = node.entity.group.getEntityById(wordBalloon.answer.entityID);
								if(npc)
								{
									var dialog:Dialog = npc.get(Dialog);
									if(dialog)
									{
										dialog.initiated = false;
									}
								}
							}
						}
					}
				}
			}
		}
		
		private function nodeAdded(node:WordBalloonNode):void
		{
			/*
			if(PlatformUtils.platformType == PlatformType.MOBILE)
			{
				if(!_zoomIn)
				{
					_zoomIn = true;
					_zoomChanged = true;
					_zoomWait = 0;
				}
			}
			*/
		}
		
		private function nodeRemoved(node:WordBalloonNode):void
		{
			/*
			if(PlatformUtils.platformType == PlatformType.MOBILE)
			{
				// Recognize that this was the last node (there are no other word balloons)
			 	if(!node.next && _zoomIn)
				{
					_zoomIn = false;
					_zoomChanged = true;
					_zoomWait = ZOOM_OUT_WAIT_TIME;
				}
			}
			*/
		}
		
		private function doZoom():void
		{
			_zoomChanged = false;
			
			_cameraNode = _cameraNodes.head;
			
			if(_cameraNode)
			{
				if(_zoomIn)
				{
					if(_cameraNode.camera.scaleTarget != ZOOM_IN_SCALE)
					{
						_defaultZoomTarget = _cameraNode.camera.scaleTarget;
						_cameraNode.camera.scaleTarget = ZOOM_IN_SCALE;
					}
				}
				else
				{
					_cameraNode.camera.scaleTarget = _defaultZoomTarget;
				}
			}
		}
		
		static public const SPEAKER_MAX_VELX:int = 100;
		
		private var _speakerNodes:NodeList;
		private var _cameraNodes:NodeList;
		private var _cameraNode:CameraNode;
		private var _zoomIn:Boolean;
		private var _zoomChanged:Boolean = false;
		private var _zoomWait:Number = 0;
		private var _defaultZoomRate:Number;
		private var _defaultZoomTarget:Number;
		private var ZOOM_OUT_WAIT_TIME:Number = 1;
		private var ZOOM_IN_SCALE:Number = 1.5;
	}
}