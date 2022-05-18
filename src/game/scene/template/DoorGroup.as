package game.scene.template
{
	import flash.display.DisplayObjectContainer;
	import flash.utils.Dictionary;
	
	import ash.core.NodeList;
	
	import engine.group.Group;
	import engine.group.Scene;
	
	import game.components.hit.Door;
	import game.creators.scene.DoorCreator;
	import game.data.game.GameEvent;
	import game.data.scene.DoorData;
	import game.data.scene.DoorParser;
	import game.data.sound.SoundAction;
	import game.data.sound.SoundParser;
	import game.nodes.scene.DoorNode;
	import game.systems.SystemPriorities;
	import game.systems.scene.DoorSystem;
	import game.util.PlatformUtils;
	import game.util.ProxyUtils;
	
	public class DoorGroup extends Group
	{
		public function DoorGroup()
		{
			super();
			super.id = GROUP_ID;
		}
		
		override public function destroy():void
		{
			_doorContainer = null;
			shellApi.eventTriggered.remove(onEventTriggered);
			
			super.destroy();
		}
		
		public function setupScene(scene:Scene, xml:XML, doorContainer:DisplayObjectContainer, audioGroup:AudioGroup = null):void
		{			
			_doorContainer = doorContainer;
			
			// add it as a child group to give it access to systemManager.
			scene.addChildGroup(this);
			addSystems(scene);
			
			addDoors(xml, audioGroup);
			
			// update the scenes doors to use connecting scene data if available.  This is used for scenes like billboards that do not have connecting scene info hardcoded in the xml.
			addConnectingSceneDoors();			
			removeConnectingSceneDoors();
			
			super.shellApi.eventTriggered.add(onEventTriggered);
		}
		
		protected function addSystems( scene:Scene ):void
		{
			scene.addSystem(new DoorSystem(), SystemPriorities.lowest);	
		}
		
		public function addDoors(doorXml:XML, audioGroup:AudioGroup = null):void
		{
			if(doorXml != null)
			{
				var doorParser:DoorParser = new DoorParser();
				_allDoorData = doorParser.parse(doorXml);
				_audioGroup = audioGroup;
				
				for each (var doorEventData:Dictionary in _allDoorData)
				{
					addDoor(doorEventData, audioGroup);
				}
			}
		}
		
		public function addDoor(eventData:Dictionary, audioGroup:AudioGroup = null, triggeredEvent:String = null):void
		{
			if(_doorCreator == null)
			{
				_doorCreator = new DoorCreator();
			}
			
			// door will only get added to scene if it has no event defined or if the defined event has been completed or just triggered.
			var door:Door = new Door();
			door.allData = eventData;
			super.shellApi.setupEventTrigger(door);
			var data:DoorData = door.data;
			
			// if an event is triggered but not saved, it will not exist in the list of completed events.  In this case, use data associated with the triggeredEvent if available.
			if(data == null)
			{
				door.data = data = eventData[triggeredEvent];
			}
			
			if( data != null && (triggeredEvent != null || (triggeredEvent == null && (data.triggeredByEvent == null || data.event != GameEvent.DEFAULT))) && !(data.doorLeadsToCommonRoom && PlatformUtils.isMobileOS))	// if there is DoorData corresponding to completed events
			{
				if(audioGroup != null)
				{
					// if a door doesn't have any specific audio, use the global scene sounds for playing door opened.
					if(audioGroup.audioData[data.id] == null)
					{
						var sceneSounds:Dictionary = audioGroup.audioData[SoundParser.SCENE_SOUND];
						if(sceneSounds != null)
						{
							audioGroup.audioData[data.id] = new Dictionary();
							
							for (var event:String in sceneSounds)
							{
								if(sceneSounds[event][SoundAction.DOOR_OPENED])
								{
									audioGroup.audioData[data.id][event] = new Dictionary();
									audioGroup.audioData[data.id][event][SoundAction.DOOR_OPENED] = sceneSounds[event][SoundAction.DOOR_OPENED];
								}
							}
						}
					}
				}
				
				if(_doorContainer[data.id] != null)
				{
					_doorContainer[data.id].visible = true;
					_doorCreator.create(_doorContainer[data.id], data, audioGroup, super.parent, door);
				}
				else
				{
					trace("DoorGroup :: Error : Door id " + data.id + " does not exist in hit container.");
				}
			}
			else
			{
				for each(var nextDoorData:DoorData in eventData)
				{
					if(_doorContainer[nextDoorData.id] != null)
					{
						_doorContainer[nextDoorData.id].visible = false;
					}
					
					return;
				}
			}
		}
		
		/**
		 * Removes the connecting scenes if we want to connect directly to the next island scene.  This is needed when no billboards are available so we don't load an empty billboard ad scene.
		 */
		public function removeConnectingSceneDoors():void
		{
			var nodes:NodeList = systemManager.getNodeList(DoorNode);
			var node:DoorNode;
			var doorData:DoorData;
			var connectingDoorData:DoorData;

			for(node = nodes.head; node; node = node.next)
			{
				doorData = node.hit.data;
				
				if(doorData.connectingSceneDoors)
				{
					for each(connectingDoorData in doorData.connectingSceneDoors)
					{
						// if we don't have any ads, link the scene exit to the next island scene that is not equal to the current scene rather than the ad scene.
						if(connectingDoorData.destinationScene != ProxyUtils.convertSceneToStorageFormat(super.parent))
						{
							trace("DoorGroup :: Skip Ad Scene: " + doorData.destinationScene);
							
							doorData.destinationSceneOld = doorData.destinationScene;
							//doorData.destinationSceneXOld = doorData.destinationSceneX;
							//doorData.destinationSceneYOld = doorData.destinationSceneY;
							//doorData.destinationSceneDirectionOld = doorData.destinationSceneDirection;

							doorData.destinationScene = connectingDoorData.destinationScene;
							doorData.destinationSceneX = connectingDoorData.destinationSceneX;
							doorData.destinationSceneY = connectingDoorData.destinationSceneY;
							doorData.destinationSceneDirection = connectingDoorData.destinationSceneDirection;
						}
					}
				}
			}
		}
		
		/**
		 * This method updates a scenes doors based on where the previous scene tells it to connect to.  So when on main st, for example, the main st left and right scene
		 * exits connect to billboard scenes that do not know anything about where their exits lead.  The main st scene, in this case, will specify this in its doors.xml.
		 * The billboard connecting scene will have its doorData modified to point to the correct scenes after being loaded in this function.
		 */
		private function addConnectingSceneDoors():void
		{
			if(this.useConnectingScenes && super.shellApi.sceneManager.connectingSceneDoors != null)
			{
				var connectingDoors:Dictionary = super.shellApi.sceneManager.connectingSceneDoors;
				var nodes:NodeList = systemManager.getNodeList(DoorNode);
				var node:DoorNode;
				var doorData:DoorData;
				var connectingDoorData:DoorData;
				
				for(node = nodes.head; node; node = node.next)
				{
					doorData = node.hit.data;
					connectingDoorData = connectingDoors[doorData.id];
					
					if(connectingDoorData)
					{
						doorData.destinationScene = connectingDoorData.destinationScene;
						doorData.destinationSceneX = connectingDoorData.destinationSceneX;
						doorData.destinationSceneY = connectingDoorData.destinationSceneY;
						doorData.destinationSceneDirection = connectingDoorData.destinationSceneDirection;
						connectingDoorData = null;
					}
				}
				
				super.shellApi.sceneManager.connectingSceneDoors = null;
			}
		}
		
		private function onEventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			addNewDoors(event);
		}
		
		private function addNewDoors(event:String):void
		{
			for each (var allEvents:Dictionary in _allDoorData)
			{
				for each (var doorEventData:DoorData in allEvents)
				{
					if(doorEventData.triggeredByEvent == event)
					{
						if(!super.parent.getEntityById(doorEventData.id))
						{
							addDoor(allEvents, _audioGroup, event);
						}
					}
				}
			}
		}
		
		private var _doorContainer:DisplayObjectContainer;
		private var _doorCreator:DoorCreator;
		private var _allDoorData:Dictionary;
		private var _audioGroup:AudioGroup;
		public var useConnectingScenes:Boolean = true;
		public static const GROUP_ID:String = "doorGroup";
	}
}