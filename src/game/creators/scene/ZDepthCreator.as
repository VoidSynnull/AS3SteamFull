package game.creators.scene
{

	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.group.Group;
	
	import game.components.entity.ZDepth;
	import game.components.entity.ZDepthControl;
	import game.systems.entity.ZDepthSystem;
	import game.util.EntityUtils;
	
	public class ZDepthCreator
	{
		private const CONTROL_ID:String = "z_control";
		
		public function createZDepth( group:Group, container:DisplayObjectContainer ):Entity
		{
			var zControlEntity:Entity = new Entity();
			zControlEntity.add( new ZDepthControl() );
			zControlEntity.add( new Display( container ) );
			zControlEntity.add( new Id( CONTROL_ID ) );
			group.addEntity(zControlEntity);
			group.addSystem( new ZDepthSystem() );

			return zControlEntity;
		}
		
		public function createZDepthEntity(group:Group, displayObject:DisplayObjectContainer, z:Number = NaN, zControlEntity:Entity = null):Entity
		{
			if( !zControlEntity )
			{
				zControlEntity = group.getEntityById( CONTROL_ID );
			}
			
			if( zControlEntity )
			{
				var zEntity:Entity = EntityUtils.createSpatialEntity( group, displayObject, Display( zControlEntity.get( Display )).displayObject )
				var zDepth:ZDepth = new ZDepth( z );
				zEntity.add( zDepth );

				return zEntity;

			}
			else
			{
				trace( "ZDepthCreator :: ZDepthControl has not yet been create, use ZDepthCreator.createZDepth prior to calling createZDepthEntity." );
				return null;
			}
		}
		
		public function addZDepthEntity(entity:Entity, z:int, zControlEntity:Entity = null, group:Group = null):void
		{
		//	trace ("[ZDepthCreator] addZDepthEntity z:" + z)
			if( !zControlEntity )
			{
				if( group )
				{
					zControlEntity = group.getEntityById( CONTROL_ID );
				}
				else
				{
					trace( "ZDepthCreator :: Must pass either zControlEntity or group." );
					return;
				}
			}
			
			if( zControlEntity )
			{
				var container:DisplayObjectContainer = Display( zControlEntity.get( Display )).displayObject;
				var display:Display = entity.get(Display);
				if( display )
				{
					display.setContainer( container );
				}
				else
				{
					trace( "ZDepthCreator :: Entity must have a Display component." );
				}
				var zDepth:ZDepth = new ZDepth( z );
				entity.add( zDepth );
			}
			else
			{
				trace( "ZDepthCreator :: ZDepthControl has not yet been create, use ZDepthCreator.createZDepth prior to calling createZDepthEntity." );
			}
		}
	}
}