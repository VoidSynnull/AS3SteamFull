package game.systems.scene
{
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.ShellApi;
	import engine.components.Audio;
	import engine.components.Display;
	
	import game.components.hit.Door;
	import game.data.ads.AdCampaignType;
	import game.data.ads.AdData;
	import game.data.ads.AdvertisingConstants;
	import game.data.scene.DoorData;
	import game.data.sound.SoundAction;
	import game.managers.ads.AdManager;
	import game.nodes.entity.collider.PlayerCollisionNode;
	import game.nodes.scene.DoorNode;
	import game.systems.SystemPriorities;
	import game.util.ClassUtils;
	import game.util.EntityUtils;
	
	public class DoorSystem extends System
	{
		public function DoorSystem()
		{
			super._defaultPriority = SystemPriorities.lowest;
		}

		override public function update(time:Number):void
		{
			var node:DoorNode;
			var collisionNode:PlayerCollisionNode;
			var hitDisplay:Display;
			
			for (node = _nodes.head; node; node = node.next)
			{
				if (EntityUtils.sleeping(node.entity))
				{
					continue;
				}
				
				if(!node.hit.opened)
				{
					collisionNode = _colliders.head;
					
					if(collisionNode)
					{
						if(node.hit.data.openOnHit && !node.hit.hitOpened)
						{
							hitDisplay = collisionNode.display;
							
							if (hitDisplay.displayObject.hitTestObject(node.display.displayObject))
							{
								node.hit.open = true;
							}
						}
					}
					
					if(node.hit.open)
					{
						node.hit.open = false;
						node.hit.opened = true;
						openDoor(node.entity);
						collisionNode.motionControl.lockInput = true;
						collisionNode.motionControl.moveToTarget = false;
						return;
					}
				}
			}
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			_nodes = systemManager.getNodeList(DoorNode);
			_colliders = systemManager.getNodeList(PlayerCollisionNode);
			
			_nodes.nodeAdded.add(nodeAdded);
			_nodes.nodeRemoved.add(nodeRemoved);
			
			var node:DoorNode;
			
			for(node = _nodes.head; node; node = node.next)
			{
				nodeAdded(node);
			}
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(DoorNode);
			systemManager.releaseNodeList(PlayerCollisionNode);
			_nodes = null;
			_colliders = null;
		}
		
		private function nodeAdded(node:DoorNode):void
		{
			node.sceneInteraction.reached.add(doorReached);
		}
		
		private function nodeRemoved(node:DoorNode):void
		{
			node.sceneInteraction.reached.remove(doorReached);
		}
		
		protected function doorReached(openingEntity:Entity, doorEntity:Entity):void
		{
			var door:Door = doorEntity.get(Door);
			door.open = true;
		}
		
		public function openDoor(doorEntity:Entity):void
		{
			var door:Door = doorEntity.get(Door);
			
			door.opening.dispatch(doorEntity);
			
			var data:DoorData = door.data;
			var audioComponent:Audio = doorEntity.get(Audio);
			
			if(audioComponent != null)
			{
				audioComponent.playCurrentAction(SoundAction.DOOR_OPENED)
			}
			
			// store the data for 'dynamic' doors here so it can be assigned to the new scene after loading.  Not in love with this approach TODO : find a better way to pass this along to the next scene.
			if(data.connectingSceneDoors)
			{
				_shellApi.sceneManager.connectingSceneDoors = data.connectingSceneDoors;
			}
			
			if(data.destinationScene != null)
			{
				loadNextScene( data );
			}
		}
		
		protected function loadNextScene( data:DoorData ):void
		{
			var destinationScene:String = data.destinationScene;
			var destinationSceneX:Number = data.destinationSceneX;
			var destinationSceneY:Number = data.destinationSceneY;
			var destinationSceneDirection:String = data.destinationSceneDirection;
			
			// if previous scene or returning from ad interior with destination of "return"
			if ( destinationScene.indexOf(PREVIOUS_SCENE) > -1 )
			{
				destinationScene = _shellApi.sceneManager.previousScene;
				destinationSceneX = _shellApi.sceneManager.previousSceneX;
				destinationSceneY = _shellApi.sceneManager.previousSceneY;
				destinationSceneDirection = _shellApi.sceneManager.previousSceneDirection;
			}
			
			var nextScene:Class = ClassUtils.getClassByName(destinationScene);
			if( nextScene != null )
			{
				var sceneClass:Class = ClassUtils.getClassByName(destinationScene);
				if (data.multiplayer)
				{
					trace("DoorSystem: loadNextScene: multiplayer scene: " + destinationScene);
					_shellApi.sceneManager.gotoMultiplayerScene(sceneClass);
				}
				else
				{
					_shellApi.loadScene(sceneClass, destinationSceneX, destinationSceneY, destinationSceneDirection);
				}
			}
			else
			{
				trace( this,":: ERROR :: loadNextScene() : Class specified by destinationScene was not found."); 
			}
		}
		
		private var _nodes:NodeList;
		private var _colliders:NodeList;
		public static const PREVIOUS_SCENE:String = "previousScene";
		[Inject]
		public var _shellApi:ShellApi;
	}
}
