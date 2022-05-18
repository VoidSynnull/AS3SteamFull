package game.scene.template
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.group.Group;
	
	import game.components.motion.nape.NapeSpace;
	import game.creators.motion.nape.NapeCreator;
	import game.systems.SystemPriorities;
	import game.systems.motion.nape.NapeInputPivotJointSystem;
	import game.systems.motion.nape.NapeSpaceSystem;
	import game.systems.motion.nape.NapeSyncToPositionSystem;
	import game.systems.motion.nape.PositionSyncToNapeSystem;
	import game.util.MotionUtils;
	
	import nape.phys.Body;
	import nape.phys.BodyType;
	import nape.shape.Polygon;
	import nape.space.Space;
	
	public class NapeGroup extends Group
	{
		public function NapeGroup()
		{
			super();
			super.id = GROUP_ID;
		}
		
		override public function destroy():void
		{
			_creator = null;
			_space = null;

			super.destroy();
		}
		
		public function setupGameScene(scene:GameScene, debug:Boolean = false):void
		{
			scene.addChildGroup(this);
			
			_creator = new NapeCreator();
			
			var areaWidth:int = scene.sceneData.bounds.width;
			var areaHeight:int = scene.sceneData.bounds.height;
			var gravity:int = MotionUtils.GRAVITY;
			var debugContainer:DisplayObjectContainer;
			// provide a container to draw nape bodies if we're debugging.
			if(debug)
			{	
				var layer:Entity = scene.getEntityById(CameraGroup.LAYER_BACKGROUND);

				if(layer == null)
				{
					debugContainer = scene.hitContainer;
				}
				else
				{
					debugContainer = new Sprite();
					var display:Display = layer.get(Display);
					display.alpha = .4;
					var container:DisplayObjectContainer = display.displayObject;
					container.addChildAt(debugContainer, container.numChildren - 1);
				}
			}
			
			var spaceEntity:Entity = _creator.createNapeSpace(gravity, areaWidth, areaHeight, debugContainer);
			
			super.addEntity(spaceEntity);
			
			_space = spaceEntity.get(NapeSpace).space;
			
			// add a 1px thick bounding box around the scene.
			addBounds(new Rectangle(0, 0, areaWidth, areaHeight), _space);
			
			addSystems();
		}
		
		public function addSystems(group:Group = null):void
		{
			if(group == null)
			{
				group = this;
			}
			
			// main Nape system - steps the simulation forward
			group.addSystem(new NapeSpaceSystem(), SystemPriorities.move);
			// syncs entities position with the nape body
			group.addSystem(new PositionSyncToNapeSystem(), SystemPriorities.moveComplete);
			// syncs the pivot joint (for picking up bodies) with the input
			group.addSystem(new NapeInputPivotJointSystem(), SystemPriorities.checkCollisions);
			// syncs nape bodies with the position of an entity
			group.addSystem(new NapeSyncToPositionSystem(), SystemPriorities.moveComplete);
		}
		
		public function addBounds(bounds:Rectangle, space:Space):void
		{
			var floor:Body = new Body(BodyType.STATIC);
			var thickness:Number = 1;
			// top
			floor.shapes.add(new Polygon(Polygon.rect(0, 0, bounds.width, thickness)));
			// right
			floor.shapes.add(new Polygon(Polygon.rect(bounds.width, 0, thickness, bounds.height)));
			// left 
			floor.shapes.add(new Polygon(Polygon.rect(0, 0, thickness, bounds.height)));
			// bottom
			floor.shapes.add(new Polygon(Polygon.rect(0, bounds.height, bounds.width, thickness)));
			floor.space = space;
			
			this.floor = floor;
		}
		
		public function makeNapeCollider(entity:Entity, body:Body):void
		{
			_creator.makeNapeCollider(entity, body, _space);
		}
		
		public function get creator():NapeCreator
		{
			return _creator;
		}
		
		public function get space():Space
		{
			return _space;
		}
		
		public static const GROUP_ID:String = "napeGroup";
		
		public var floor:Body;
		
		private var _creator:NapeCreator;
		private var _space:Space;
		
	}
}