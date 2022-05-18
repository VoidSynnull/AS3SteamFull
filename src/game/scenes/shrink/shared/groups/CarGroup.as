package game.scenes.shrink.shared.groups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	import engine.group.Scene;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.collider.BitmapCollider;
	import game.components.entity.collider.SceneCollider;
	import game.components.entity.collider.WallCollider;
	import game.components.hit.CurrentHit;
	import game.components.hit.Platform;
	import game.components.motion.Edge;
	import game.components.motion.FollowTarget;
	import game.creators.ui.ToolTipCreator;
	import game.scene.template.ItemGroup;
	import game.scenes.shrink.ShrinkEvents;
	import game.scenes.shrink.shared.Systems.CarControlSystem.CarControl;
	import game.scenes.shrink.shared.Systems.CarControlSystem.CarControlSystem;
	import game.scenes.shrink.shared.Systems.CarSystem.Car;
	import game.scenes.shrink.shared.Systems.CarSystem.CarSystem;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DataUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	
	import org.osflash.signals.Signal;
	
	public class CarGroup extends Group
	{
		private const CAR_URL:String = "scenes/shrink/shared/car.swf";
		private const START_SCENE:String = "LivingRoomShrunk";
		private var container:DisplayObjectContainer;
		private var _events:ShrinkEvents;
		private var player:Entity;
		private var scene:Scene;
		private var car:Entity;
		private var startPoint:Point;
		
		public function CarGroup(container:DisplayObjectContainer, scene:Scene, startPoint:Point = null)
		{
			carSetUp = new Signal(Entity);
			gotInOrOutOfCar = new Signal(Boolean);
			this.container = container;
			this.scene = scene;
			shellApi = this.scene.shellApi;
			player = shellApi.player;
			
			findStartPosition(startPoint);
		}
		
		private function findStartPosition(point:Point):void
		{
			if(shellApi.checkEvent(_events.IN_CAR))
			{
				loadCar(null , new Point(player.get(Spatial).x, scene.sceneData.bounds.bottom - 100));
				return;
			}
			
			shellApi.getUserField(_events.CAR_FIELD, shellApi.island, Command.create(loadCar, point), true);
		}
		
		private function loadCar(saveString:String = null, point:Point = null):void
		{
			if(!DataUtils.validString(saveString) && point == null)
				return;
			
			if(DataUtils.validString(saveString))
			{
				var carInfo:Array = String(saveString).split(",");
				
				if(carInfo[0] != shellApi.sceneName)
					return;
				
				startPoint = new Point(carInfo[1], scene.sceneData.bounds.bottom - 100);
			}
			else
				startPoint = point;// in the case that you load into the scene in which the car starts and it has not been interacted with yet
			
			shellApi.loadFiles([shellApi.assetPrefix+CAR_URL],onCarLoaded);
		}
		
		public function onCarLoaded():void
		{
			addSystem(new CarSystem());
			addSystem(new CarControlSystem());
			var clip:MovieClip = shellApi.getFile(shellApi.assetPrefix+CAR_URL);
			BitmapUtils.convertContainer(clip);
			
			clip = clip.car;
			clip.x = startPoint.x;
			clip.y = startPoint.y;
			
			var body:MovieClip = clip["body"]["bodyVector"];
			body.mouseChildren = body.mouseEnabled = false;
			
			var carRect:Rectangle = clip.getRect(clip);
			
			car = EntityUtils.createMovingEntity(parent, clip, container);
			DisplayUtils.moveToOverUnder(clip, EntityUtils.getDisplayObject(player), false);
			
			car.add(new Car(clip, parent)).add(new CarControl(player.get(Motion)))
				.add(new Id("car")).add(new CurrentHit()).add(new WallCollider())
				.add(new BitmapCollider()).add(new SceneCollider()).add(new Audio())
				.add(new Edge(carRect.left, carRect.top,carRect.width,carRect.height));
			
			var motion:Motion = car.get(Motion);
			motion.friction = new Point(500, 1000);
			
			for(var p:int = 1; p <= 2; p++)
			{
				var plat:MovieClip = clip["platform"+p];
				plat.mouseEnabled = plat.mouseChildren = false;
				var entity:Entity = EntityUtils.createSpatialEntity(parent, plat, container);
				var follow:FollowTarget = new FollowTarget(car.get(Spatial));
				follow.offset = new Point(plat.x, plat.y);
				entity.add(new Platform()).add(follow);
				Display(entity.get(Display)).alpha = 0;
			}
			
			var interactionNames:Array = ["hit","body.battery","body.hatch"];
			var interactionFunctions:Array = [clickDoor,clickBattery,clickHatch];
			
			for(var i:int = 0; i < interactionNames.length; i++)
			{
				var names:Array = String(interactionNames[i]).split(".");
				var interact:MovieClip = clip;
				for(var n:int = 0; n < names.length; n++)
				{
					interact = interact[names[n]];
				}
				var ent:Entity = EntityUtils.createSpatialEntity(parent, interact, interact.parent);
				var interaction:Interaction = InteractionCreator.addToEntity(ent, ["click"], interact);
				ToolTipCreator.addToEntity(ent);
				interaction.click.add(interactionFunctions[i]);
				
				ent.add(new Id(clip.name + "_" + interact.name));
			}
			
			if(!shellApi.checkEvent(_events.CAR_HAS_BATTERY))
			{
				Spatial(parent.getEntityById("car_hatch").get(Spatial)).rotation = 15;
				Display(parent.getEntityById("car_battery").get(Display)).visible = false;
			}
			
			Display(parent.getEntityById("car_hit").get(Display)).alpha = 0;
			
			if(shellApi.checkEvent(_events.IN_CAR))
				getInCar();
			carSetUp.dispatch(car);
		}
		
		private function clickDoor(door:Entity):void
		{
			if(shellApi.checkHasItem(_events.REMOTE_CONTROL))
			{
				if(shellApi.checkEvent(_events.CAR_HAS_BATTERY))
				{
					if(shellApi.checkEvent(_events.IN_CAR))
						getOutCar();
					else
						getIn();
				}
				else
					Dialog(player.get(Dialog)).sayById(_events.NEEDS + _events.BATTERY);
			}
			else
				Dialog(player.get(Dialog)).sayById(_events.NEEDS + _events.REMOTE_CONTROL);
		}
		
		private function getIn():void
		{
			var carSpatial:Spatial = car.get(Spatial);
			CharUtils.moveToTarget(player, carSpatial.x, carSpatial.y,false,getInCar).ignorePlatformTarget = true;
		}
		
		private function getInCar(...args):void
		{
			shellApi.completeEvent(_events.IN_CAR);
			Display(player.get(Display)).visible = false;
			player.add(new FollowTarget(car.get(Spatial)));
			FollowTarget(player.get(FollowTarget)).offset = new Point(-75,75);//so it looks like his running dust particles are coming from the tire 
			CarControl(car.get(CarControl)).inCar = true;
			gotInOrOutOfCar.dispatch(true);
		}
		
		private function getOutCar():void
		{
			shellApi.removeEvent(_events.IN_CAR);
			Display(player.get(Display)).visible = true;
			player.remove(FollowTarget);
			
			var carSaveString:String = shellApi.sceneName+","+car.get(Spatial).x;
			shellApi.setUserField(_events.CAR_FIELD,carSaveString,shellApi.island,true);
			
			CarControl(car.get(CarControl)).inCar = false;
			gotInOrOutOfCar.dispatch(false);
		}
		
		private function clickBattery(battery:Entity):void
		{
			shellApi.triggerEvent("grab_battery");
			Display(battery.get(Display)).visible = false;
			ItemGroup(getGroupById(ItemGroup.GROUP_ID)).showAndGetItem(_events.BATTERY);
			shellApi.removeEvent(_events.CAR_HAS_BATTERY);
		}
		
		private function clickHatch(hatch:Entity):void
		{
			if(!shellApi.checkEvent(_events.CAR_HAS_BATTERY))
				return;
			Dialog(player.get(Dialog)).sayById(_events.NEEDS + _events.SCREW_DRIVER);
		}
		
		public var carSetUp:Signal;
		public var gotInOrOutOfCar:Signal;
	}
}