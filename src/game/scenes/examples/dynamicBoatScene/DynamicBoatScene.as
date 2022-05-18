package game.scenes.examples.dynamicBoatScene
{
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	
	import game.components.hit.BitmapHitArea;
	import game.data.vehicle.VehicleData;
	import game.scene.template.CollisionGroup;
	import game.scene.template.topDown.boatScene.BoatScene;
	import game.systems.SystemPriorities;
	import game.systems.scene.DoorSystem;
	
	public class DynamicBoatScene extends BoatScene
	{
		public function DynamicBoatScene()
		{
			super();
		}
				
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.init(container);
		}
		
		override protected function addGroups():void
		{
			super.addGroups();
			
			super.addSystem(new DoorSystem(), SystemPriorities.lowest);	
			
			var islandContainer:Sprite = new Sprite();
			super.hitContainer.addChild(islandContainer);
			
			/*
			// for hit debug
			super.hitContainer.mouseChildren = false;
			super.hitContainer.mouseEnabled = false;
			islandContainer.mouseChildren = false;
			islandContainer.mouseEnabled = false;
			*/
			
			// Create a new vehicle by creating a VehicleData instance...
			var playerData:VehicleData = new VehicleData();
			playerData.url = super.groupPrefix + "boat.swf";
			playerData.x = super.shellApi.profileManager.active.lastX;
			playerData.y = super.shellApi.profileManager.active.lastY;
			playerData.target = super.shellApi.inputEntity.get(Spatial);
			playerData.isPlayer = true;
			playerData.id = "player";
			
			super.loadVehicle(playerData);
			
			_creator = new DynamicBoatSceneCreator(islandContainer);
			
			var parser:GridElementParser = new GridElementParser();
			_creator.createAllFromData(parser.parse(super.getData("gridElements.xml")), this);
			
			setupBitmapHits();
			
			super.addSystem(new EntityGridSystem(), SystemPriorities.moveComplete);
		}
		
		private function setupBitmapHits():void
		{
			var hitEntity:Entity = super.getEntityById(CollisionGroup.HITAREA_ENTITY_ID);
			var hitArea:BitmapHitArea = hitEntity.get(BitmapHitArea);
			var hitAreaSpatial:Spatial = hitEntity.get(Spatial);
			var width:Number = super.sceneData.bounds.width * hitAreaSpatial.scale;
			var height:Number = super.sceneData.bounds.height * hitAreaSpatial.scale;
			
			hitArea.bitmapData = new BitmapData(width, height);
		}
		
		override protected function vehicleLoaded(entity:Entity):void
		{
			super.addWake(entity, super.groupPrefix + "waterRipple.swf");
			super.addPerspectiveAnimation(entity, "boatLayers.xml");
		}
		
		private var _creator:DynamicBoatSceneCreator;
	}
}