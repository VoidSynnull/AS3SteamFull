package engine.group
{
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.display.BitmapWrapper;
	import game.scenes.carrot.factory.Factory;
	import game.util.AudioUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	
	public class TransportGroup extends Group
	{
		public function TransportGroup()
		{
			super(); 
			super.id = GROUP_ID;
		}
		
		public function init():void
		{
			transportOut(shellApi.player);
		}
		
		/**
		 * Teleport an entity out of a scene
		 * @param	target : The entity to teleport in.
		 * @param   isPlayer : is this entity the player
		 * @param   targetX : starting X-location for the next scene
		 * @param   targetY : starting Y-location for the next scene
		 * @param   direction : starting direction for the next scene
		 * @param   scene : destination scene
		 */
		public function transportOut( target:Entity, isPlayer:Boolean = true, targetX:Number = NaN, targetY:Number = NaN, direction:String = null, scene = null ):void
		{
			if( scene )
			{
				targetScene = scene;
			}
			var hex:uint = 0xFFFFFF;
			var spatial:Spatial = target.get( Spatial );
			var tween:Tween = new Tween();
			
			var display:Display = EntityUtils.getDisplay( target );
			display.alpha = 0;
			
			// copy to be faded to alpha 0
			var wrapper:BitmapWrapper =	DisplayUtils.convertToBitmapSprite(display.displayObject, null, 1, false, display.container);
			
			//var point:Point = DisplayUtils.localToLocal( spatial.x, spatial.y, display.displayObject.parent, display.container );
			wrapper.sprite.x = spatial.x;
			wrapper.sprite.y = spatial.y;
			
			var entity:Entity = EntityUtils.createSpatialEntity( super.parent, wrapper.sprite, display.container );
			entity.add( tween );
			display = EntityUtils.getDisplay( entity );
			
			tween.to( display, 1.5, { alpha : 0 } );
			
			if( isPlayer )
			{
				SceneUtil.lockInput( this, true, true );
				playerX = targetX;
				playerY = targetY;
				playerDirection = direction;
				SceneUtil.setCameraTarget( shellApi.sceneManager.currentScene, entity );
			}
			else
			{
				ToolTipCreator.removeFromEntity( target );
			}
			
			// copy to be faded to white then alpha 0
			wrapper = DisplayUtils.convertToBitmapSprite( display.displayObject, null, 1, false, display.container );
			wrapper.sprite.x = spatial.x;
			wrapper.sprite.y = spatial.y;
			
			var white:ColorTransform = new ColorTransform( 1, 1, 1, 0, 0, 0 );
			
			white.redOffset = (hex >> 16) & 0xFF;	
			white.greenOffset = (hex >> 8) & 0xFF;
			white.blueOffset = hex & 0xFF;
			wrapper.sprite.transform.colorTransform = white;
			
			entity = EntityUtils.createSpatialEntity( super.parent, wrapper.sprite, display.container );
			
			AudioUtils.play( super.parent, SoundManager.EFFECTS_PATH + TELEPORT );
			super.shellApi.triggerEvent( TELEPORT_EVENT, true );
			
			tween = new Tween();
			entity.add( tween );
			
			display = entity.get( Display );
			tween.from( display, 1.5, { alpha : 0, onComplete : fadeOutPlayer, onCompleteParams : [ entity, isPlayer ]});
			
			
			super.removeEntity( target );
		}
		
		private function fadeOutPlayer( entity:Entity, isPlayer:Boolean ):void
		{
			var tween:Tween = entity.get( Tween );
			var display:Display = entity.get( Display );
			
			tween.to( display, 1.5, { alpha : 0, onComplete : onColorized, onCompleteParams:[ entity, isPlayer ] });
		}
		
		private function onColorized(entity:Entity, isplayer:Boolean = true):void
		{
			if(isplayer){
				super.shellApi.loadScene( targetScene, playerX, playerY, playerDirection );
			}else if(entity){
				removeEntity(entity);
			}
		}
		
		/**
		 * Teleport an entity into the scene
		 * @param	target : The entity to teleport in.
		 * @param   isPlayer : is this entity the player
		 */
		public function transportIn( target:Entity, isPlayer:Boolean = true, delay:Number = .5, handler:Function = null ):void
		{
			var display:Display = target.get( Display );
			display.alpha = 0;
			SceneUtil.addTimedEvent( this, new TimedEvent( delay, 1, Command.create( fadeIn, target, isPlayer, handler )));
		}
		
		private function fadeIn( target:Entity, isPlayer:Boolean = true, handler:Function = null ):void
		{
			shellApi.triggerEvent( TELEPORT_EVENT );
			AudioUtils.play( super.parent, SoundManager.EFFECTS_PATH + TELEPORT );
			
			if( isPlayer )
			{
				SceneUtil.lockInput( this, true, false );
			}
			var display:Display = EntityUtils.getDisplay( target );
			var spatial:Spatial = target.get( Spatial );
			
			var wrapper:BitmapWrapper =	DisplayUtils.convertToBitmapSprite(display.displayObject, null, 1, false, display.container);
			//var wrapper:BitmapWrapper =	DisplayUtils.convertToBitmapSprite( display.displayObject, true, 0, display.container, null, false );	
			
			//var point:Point = DisplayUtils.localToLocal( spatial.x, spatial.y, display.displayObject.parent, display.container );
			wrapper.sprite.x = spatial.x;
			wrapper.sprite.y = spatial.y;
			
			// copy to be faded from white to color
			var colorEntity:Entity = EntityUtils.createSpatialEntity( super.parent, wrapper.sprite, display.container );
			Display( colorEntity.get( Display )).alpha = 0;
			colorEntity.add( new Tween())
			
			// copy to be faded to white then alpha
			wrapper = DisplayUtils.convertToBitmapSprite(display.displayObject, null, 1, false, display.container);
			//wrapper = DisplayUtils.convertToBitmapSprite( display.displayObject, true, 0, display.container, null, false );	
			wrapper.sprite.x = spatial.x;
			wrapper.sprite.y = spatial.y;
			
			var origin:ColorTransform = display.displayObject.transform.colorTransform;
			var hex:uint = 0xFFFFFF;		
			var white:ColorTransform = new ColorTransform( 1, 1, 1, 0, 0, 0 );
			white.redOffset = (hex >> 16) & 0xFF;
			white.greenOffset = (hex >> 8) & 0xFF;
			white.blueOffset = hex & 0xFF;
			wrapper.sprite.transform.colorTransform = white;	
			
			var whiteEntity:Entity = EntityUtils.createSpatialEntity( super.parent, wrapper.sprite, display.container );
			display = whiteEntity.get( Display );
			display.alpha = 0;
			
			var tween:Tween = new Tween();
			whiteEntity.add( tween );
			
			tween.to( display, 1.5, { alpha : 1, onComplete : fadeInPlayer, onCompleteParams : [ whiteEntity, colorEntity, target, isPlayer, handler ]});
		}
		
		private function fadeInPlayer( whiteEntity:Entity, colorEntity:Entity, target:Entity, isPlayer:Boolean, handler:Function = null ):void
		{
			var tween:Tween = whiteEntity.get( Tween );
			var display:Display = whiteEntity.get( Display );
			
			tween.to( display, 1.5, { alpha : 0 });
			
			tween = colorEntity.get( Tween );
			display = colorEntity.get( Display );
			tween.to( display, 1.5, { alpha : 1, onComplete : regainControl, onCompleteParams : [ whiteEntity, colorEntity, target, isPlayer, handler ]});
		}
		
		private function regainControl( whiteEntity:Entity, colorEntity:Entity, target:Entity, isPlayer:Boolean, handler:Function = null ):void
		{
			super.removeEntity( whiteEntity );
			super.removeEntity( colorEntity );
			Display( target.get( Display )).alpha = 1;
			if( isPlayer )
			{
				shellApi.removeEvent( TELEPORT_EVENT );
				shellApi.triggerEvent( TELEPORT_FINISHED );
				SceneUtil.lockInput( this, false, false );
			}
			if( handler )
			{
				handler();
			}
		}
		
		public var targetScene:Class = Factory;
		public var direction:String = null;
		public var playerX:Number;
		public var playerY:Number;
		public var playerDirection:String;
		private var TELEPORT_EVENT:String = "teleport";
		private var TELEPORT_FINISHED:String = "teleport_finished";
		private var TELEPORT:String = "event_06.mp3";
		
		public static const GROUP_ID:String = "transportGroup";
	}
}