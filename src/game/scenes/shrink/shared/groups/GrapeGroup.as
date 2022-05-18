package game.scenes.shrink.shared.groups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.group.Group;
	import engine.group.Scene;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.scenes.shrink.ShrinkEvents;
	import game.scenes.shrink.shared.Systems.CarrySystem.Carry;
	import game.util.DataUtils;
	import game.util.MotionUtils;
	import game.util.PlatformUtils;
	
	import org.osflash.signals.Signal;
	
	public class GrapeGroup extends Group
	{
		private const GRAPE_URL:String = "scenes/shrink/shared/grape.swf";
		private const START_SCENE:String = "KitchenShrunk02";
		private var _events:ShrinkEvents;
		private var player:Entity;
		private var container:DisplayObjectContainer;
		private var scene:Scene;
		private var grape:Entity;
		private var motion:Motion;
		private var startPoint:Point = new Point();
		private var clip:MovieClip;
		
		public var grapeSetUp:Signal;
		public var pickUpDropGrape:Signal;
		private var _carryGroup:CarryGroup;
		
		public function get holdingGrape():Boolean{return (grape != null) ? Carry(grape.get(Carry)).holding : false;}
		
		public function GrapeGroup(container:DisplayObjectContainer, scene:Scene, point:Point = null)
		{
			_carryGroup = scene.getGroupById(CarryGroup.GROUP_ID) as CarryGroup;
			
			grapeSetUp = new Signal(Entity);
			pickUpDropGrape = new Signal(Boolean);
			
			this.container = container;
			this.scene = scene;
			
			shellApi = this.scene.shellApi;
			player = shellApi.player;
			
			if(!shellApi.checkEvent(_events.GRAPE_DROPPED) && shellApi.sceneName != START_SCENE)
			{
				grapeSetUp.dispatch(null);
				return;
			}
			
			findStartPoint(point);
		}
		
		private function findStartPoint(point:Point):void
		{
			if(shellApi.checkEvent(_events.HAS_GRAPE))
			{
				point = new Point(player.get(Spatial).x, player.get(Spatial).y);
				loadGrape(null, point);
				return;
			}
			
			if(!shellApi.checkEvent(_events.GRAPE_DROPPED) && shellApi.sceneName == START_SCENE)
			{
				loadGrape(null, point);
				return;
			}
			
			shellApi.getUserField(_events.GRAPE_FIELD, shellApi.island, Command.create(loadGrape, point), true);
		}
		
		private function loadGrape(saveString:String = null, point:Point = null):void
		{
			if(!DataUtils.validString(saveString) && point == null)
				return;
			
			if(DataUtils.validString(saveString))
			{
				var grapeInfo:Array = String(saveString).split(",");
				
				if(grapeInfo[0] != shellApi.sceneName)
					return;
				
				startPoint = new Point(grapeInfo[1],  grapeInfo[2]);
			}
			else
				startPoint = point;// in the case that you load into the scene in which the car starts and it has not been interacted with yet
			
			if(clip == null)
				shellApi.loadFiles([shellApi.assetPrefix+GRAPE_URL],onGrapeLoaded);
			else
				setUpGrape();
		}
		
		public function onGrapeLoaded():void
		{
			clip = shellApi.getFile(shellApi.assetPrefix+GRAPE_URL)["content"];
			setUpGrape();
		}
		
		private function setUpGrape():void
		{
			clip.x = startPoint.x;
			clip.y = startPoint.y;
			
			var grapeEdge:Rectangle = clip.getRect(clip);
			
			grape = _carryGroup.createCarryEntity(scene, clip, container).add(new Id("grape"));
			
			Carry(grape.get(Carry)).pickUpDropItem.add(pickUpDropItem);
			
			motion = grape.get(Motion);
			motion.friction = new Point(100,0);
			//*/
			if(shellApi.checkEvent(_events.GRAPE_DROPPED))
				motion.acceleration = new Point(0, MotionUtils.GRAVITY);
			
			if(shellApi.checkEvent(_events.HAS_GRAPE))
				_carryGroup.pickUpItem(player, grape);
			
			grapeSetUp.dispatch(grape);
		}
		
		private function pickUpDropItem(grape:Entity, bool:Boolean):void
		{
			if(grape != this.grape)
				return;
			
			if(bool)
			{
				shellApi.completeEvent(_events.HAS_GRAPE);
				
				pickUpDropGrape.dispatch(true);
				
				Dialog(player.get(Dialog)).sayById("heavy");
			}
			else
			{
				shellApi.removeEvent(_events.HAS_GRAPE);
				
				var grapeSaveString:String = shellApi.sceneName+","+grape.get(Spatial).x+","+grape.get(Spatial).y;
				shellApi.setUserField(_events.GRAPE_FIELD, grapeSaveString, shellApi.island, true);
				
				pickUpDropGrape.dispatch(false);
			}
		}
		
		public function dropGrape():void
		{
			_carryGroup.dropItem(grape, player);
		}
	}
}