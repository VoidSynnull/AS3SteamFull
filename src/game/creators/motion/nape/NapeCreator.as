package game.creators.motion.nape
{
	import com.poptropica.Assert;
	
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.motion.nape.NapeMotion;
	import game.components.motion.nape.NapePivotJoint;
	import game.components.motion.nape.NapeSpace;
	import game.components.motion.nape.NapeSyncToPosition;
	import game.components.motion.nape.PositionSyncToNape;
	
	import nape.constraint.PivotJoint;
	import nape.geom.Vec2;
	import nape.phys.Body;
	import nape.space.Space;
	import nape.util.BitmapDebug;
	import nape.util.Debug;

	public class NapeCreator
	{
		public function NapeCreator()
		{
		}
		
		public function createNapeSpace(gravityY:Number, debugWidth:Number = 0, debugHeight:Number = 0, debugContainer:DisplayObjectContainer = null):Entity
		{
			var entity:Entity = new Entity();
			var gravity:Vec2 = Vec2.weak(0, gravityY);
			var space:Space = new Space(gravity);
			var debugTarget:Debug = null;
			
			if(debugContainer != null)
			{			
				Assert.assert(debugWidth != 0 && debugHeight != 0, "Debug area must be greater than zero for debugging.");
				debugTarget = new BitmapDebug(debugWidth, debugHeight, 0x000000);
				debugTarget.drawConstraints = true;
				debugContainer.addChild(debugTarget.display);
			}
			
			entity.add(new NapeSpace(space, debugTarget));
			entity.add(new Id(SPACE_ENTITY));
			
			return entity;
		}
		
		public function createNapeObject(x:Number, y:Number, space:Space, body:Body, id:String = null):Entity
		{
			var entity:Entity = new Entity();

			body.position.setxy(x, y);
			body.space = space;
			entity.add(new NapeMotion(body));
			entity.add(new Spatial(x, y));
			entity.add(new Motion());
			entity.add(new PositionSyncToNape());
			
			if(id != null)
			{
				entity.add(new Id(id));
			}
			
			return entity;
		}
		
		public function createNapeCollider(x:Number, y:Number, space:Space, body:Body, id:String = null):Entity
		{
			var entity:Entity = new Entity();
			
			body.position.setxy(x, y);
			body.space = space;
			entity.add(new NapeMotion(body));
			entity.add(new Spatial(x, y));
			entity.add(new Motion());
			entity.add(new NapeSyncToPosition());
			
			if(id != null)
			{
				entity.add(new Id(id));
			}
			
			return entity;
		}
		
		public function makeNapeCollider(entity:Entity, body:Body, space:Space = null):void
		{
			if(space != null)
			{
				body.space = space;
			}
			
			entity.add(new NapeMotion(body));
			entity.add(new NapeSyncToPosition());
			
			if(entity.get(Motion) == null)
			{
				entity.add(new Motion());
			}
			
			if(entity.get(Spatial) == null)
			{
				entity.add(new Spatial());
			}
			
			var spatial:Spatial = entity.get(Spatial);
			
			if(spatial)
			{
				body.position.x = spatial.x;
				body.position.y = spatial.y;
			}
		}
		
		public function createNapeInputPivotJoint(space:Space, stiff:Boolean = false):Entity
		{
			var entity:Entity = new Entity();
			var input:PivotJoint = new PivotJoint(space.world, null, Vec2.weak(), Vec2.weak());
			input.space = space;
			input.active = false;
			input.stiff = stiff;
			entity.add(new NapePivotJoint(input));
			entity.add(new Id(INPUT_ENTITY));
			
			return entity;
		}

		
		public function cleanUpEntity(entity:Entity):void
		{
			
		}
		
		public static const SPACE_ENTITY:String = "napeSpace";
		public static const INPUT_ENTITY:String = "napeInput";
	}
}