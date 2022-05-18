package game.scenes.deepDive3.shared.groups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.group.DisplayGroup;
	import engine.group.Group;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.components.hit.Radial;
	import game.components.timeline.Timeline;
	import game.scenes.deepDive3.shared.components.TriggerDoor;
	import game.scenes.deepDive3.shared.nodes.TriggerDoorNode;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.TimelineUtils;
	
	public class TriggerDoorGroup extends Group
	{
		private const OPEN:String = "open";
		private const CLOSE:String = "close";
		private const OPENED:String = "opened";
		private const CLOSED:String = "closed";
		public static const GROUP_ID:String = "triggerDoorGroup";
		
		public function TriggerDoorGroup()
		{
			super();
			this.id = GROUP_ID;
		}	
		
		// TODO :: Ideally doors share bitmap data
		public function setupDoors( group:DisplayGroup, container:DisplayObjectContainer, doorId:String = "tDoor", hitId:String = "tDoorHit", startIndex:int = 1 ):void
		{
			var bitmapQuality:Number = PerformanceUtils.defaultBitmapQuality;
			
			var doorEntity:Entity;
			var clip:MovieClip;
			var hitEntity:Entity;
			var i:int = startIndex;
			for (i; container[doorId+i] != null; i++)
			{
				clip = container[doorId+i];
				group.convertContainer( clip, bitmapQuality );
				doorEntity = EntityUtils.createSpatialEntity(group, clip);
				TimelineUtils.convertClip( clip, group, doorEntity, null, false);
				Timeline(doorEntity.get(Timeline)).labelReached.add(Command.create(labelReached, doorEntity));
				
				doorEntity.add(new Sleep(false,true));
				doorEntity.add(new Id(doorId+i));
				hitEntity = group.getEntityById(hitId+i);
				doorEntity.add(new TriggerDoor(Radial, hitEntity, null,doorEntity.get(Radial)));
				
				Display(doorEntity.get(Display)).moveToFront();
			}
		}
		
		public function openDoors(name:String):void 
		{
			var nodeList:NodeList = super.systemManager.getNodeList( TriggerDoorNode );
			for( var node : TriggerDoorNode = nodeList.head; node; node = node.next )
			{
				if(node.triggerDoor.doorSets.indexOf(name) != -1)
				{
					if(node.timeline.getLabelIndex(OPEN) != -1)
					{
						node.timeline.reverse = false;
						node.timeline.gotoAndPlay(OPEN);
					}
					else
					{
						node.timeline.gotoAndStop(OPENED);
					}
				}
			}
		}
		
		public function setOpenedSDoors(name:String):void 
		{
			var nodeList:NodeList = super.systemManager.getNodeList( TriggerDoorNode );
			for( var node : TriggerDoorNode = nodeList.head; node; node = node.next )
			{
				if(node.triggerDoor.doorSets.indexOf(name) != -1){
					node.timeline.gotoAndStop(OPENED);
				}
			}
		}
		
		public function closeDoors(name:String):void 
		{
			var nodeList:NodeList = super.systemManager.getNodeList( TriggerDoorNode );
			for( var node : TriggerDoorNode = nodeList.head; node; node = node.next )
			{
				if(node.triggerDoor.doorSets.indexOf(name) != -1)
				{
					// if 'close' label defined play from close
					if(node.timeline.getLabelIndex(CLOSE) != -1)
					{
						node.timeline.reverse = false;
						node.timeline.gotoAndPlay(CLOSE);
					}
						// if 'close' label not defined, reverse timeline
					else
					{
						node.timeline.reverse = true;
						node.timeline.gotoAndPlay(OPENED);
					}
				}
			}
		}
		
		public function setClosedDoors(name:String):void 
		{
			var nodeList:NodeList = super.systemManager.getNodeList( TriggerDoorNode );
			for( var node : TriggerDoorNode = nodeList.head; node; node = node.next )
			{
				if(node.triggerDoor.doorSets.indexOf(name) != -1){
					node.timeline.gotoAndStop(CLOSED);
				}
			}
		}
		
		private function labelReached(label:String, entity:Entity):void 
		{
			if(label == OPENED)
			{
				entity.get(TriggerDoor).hit.remove(entity.get(TriggerDoor).hitClass);
			}
			else if( label == CLOSED )
			{
				entity.get(TriggerDoor).hit.add(entity.get(TriggerDoor).originalHit);
			}
		}
	}
}