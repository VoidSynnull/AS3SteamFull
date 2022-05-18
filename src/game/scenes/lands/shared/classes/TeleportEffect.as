package game.scenes.lands.shared.classes {

	/**
	 * 
	 * Modified TransportGroup to not actually change scene, not fire events, not remove teleport target.
	 * Entities aren't removed on teleport out since the scene isn't changing.
	 * 
	 */

	import flash.geom.ColorTransform;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.group.Group;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.display.BitmapWrapper;
	import game.util.AudioUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	
	public class TeleportEffect {

		private var TELEPORT_SOUND:String = "event_06.mp3";

		private var myGroup:Group;

		private var onTeleportIn:Function;
		private var onTeleportOut:Function;

		private var whiteEntity:Entity;
		private var colorEntity:Entity;

		public function TeleportEffect( grp:Group ) {

			this.myGroup = grp;

		} // TeleportEffect
		
		/**
		 * Teleport an entity out of a scene
		 * @param	target : The entity to teleport.
		 * @param   isPlayer : is this entity the player
		 * @param   targetX : starting X-location for the next scene
		 * @param   targetY : starting Y-location for the next scene
		 */
		public function teleportOut( target:Entity, isPlayer:Boolean = true, onComplete:Function=null ):void {

			this.onTeleportOut = onComplete;

			var spatial:Spatial = target.get( Spatial );
			var tween:Tween = new Tween();
			
			var display:Display = EntityUtils.getDisplay( target );
			display.alpha = 0;
			
			// copy to be faded to alpha 0
			var wrapper:BitmapWrapper =	DisplayUtils.convertToBitmapSprite(display.displayObject, null, 1, false, display.container);
			
			//var point:Point = DisplayUtils.localToLocal( spatial.x, spatial.y, display.displayObject.parent, display.container );
			wrapper.sprite.x = spatial.x;
			wrapper.sprite.y = spatial.y;
			
			this.whiteEntity =  EntityUtils.createSpatialEntity( this.myGroup, wrapper.sprite, display.container );
			this.whiteEntity.add( tween );
			display = EntityUtils.getDisplay( this.whiteEntity );
			
			tween.to( display, 1.5, { alpha : 0 } );
			
			if( isPlayer ) {

				SceneUtil.lockInput( this.myGroup, true, true );

			} else {

				ToolTipCreator.removeFromEntity( target );
			}
			
			// copy to be faded to white then alpha 0
			wrapper = DisplayUtils.convertToBitmapSprite( display.displayObject, null, 1, false, display.container );
			wrapper.sprite.x = spatial.x;
			wrapper.sprite.y = spatial.y;

			var white:ColorTransform = new ColorTransform( 1, 1, 1, 0, 0xFF, 0xFF, 0xFF );
			wrapper.sprite.transform.colorTransform = white;

			this.colorEntity = EntityUtils.createSpatialEntity( this.myGroup, wrapper.sprite, display.container );

			AudioUtils.play( this.myGroup, SoundManager.EFFECTS_PATH + TELEPORT_SOUND );

			tween = new Tween();
			this.colorEntity.add( tween );
			
			display = this.colorEntity.get( Display );
			tween.from( display, 1.5, { alpha : 0, onComplete : fadeOutPlayer } );

			if ( !isPlayer ) {

				this.myGroup.removeEntity( target );

			} else {

				// sleep? make invisible?

			} //

		} //
		
		private function fadeOutPlayer():void {

			var tween:Tween = this.colorEntity.get( Tween );
			var display:Display = this.colorEntity.get( Display );
			
			tween.to( display, 1.5, { alpha : 0, onComplete : teleportDone } );

		}
		
		private function teleportDone():void {

			this.myGroup.removeEntity( this.whiteEntity );
			this.myGroup.removeEntity( this.colorEntity );

			// COMPLETE
			if ( this.onTeleportOut ) {
				this.onTeleportOut();
			}

		} ///
		
		/**
		 * Teleport an entity into the scene
		 * @param	target : The entity to teleport in.
		 * @param   isPlayer : is this entity the player
		 */
		public function teleportIn( target:Entity, isPlayer:Boolean = true, onComplete:Function=null, delay:Number = .5 ):void {

			this.onTeleportIn = onComplete;

			var display:Display = target.get( Display );
			display.displayObject.visible = true;
			display.visible = true;
			SceneUtil.addTimedEvent( this.myGroup, new TimedEvent( delay, 1, Command.create( fadeIn, target, isPlayer )));

		} //
	
		private function fadeIn( target:Entity, isPlayer:Boolean = true ):void {

			AudioUtils.play( this.myGroup, SoundManager.EFFECTS_PATH + TELEPORT_SOUND );
			
			if ( isPlayer ) {
				SceneUtil.lockInput( this.myGroup, true, false );
			}
			var display:Display = EntityUtils.getDisplay( target );
			var spatial:Spatial = target.get( Spatial );

			var wrapper:BitmapWrapper =	DisplayUtils.convertToBitmapSprite(display.displayObject, null, 1, false, display.container);

			display.alpha = 0;

			wrapper.sprite.x = spatial.x;
			wrapper.sprite.y = spatial.y;
			
			// copy to be faded from white to color
			this.colorEntity = EntityUtils.createSpatialEntity( this.myGroup, wrapper.sprite, display.container );
			Display( colorEntity.get( Display )).alpha = 0;
			colorEntity.add( new Tween())
				
			// copy to be faded to white then alpha
			wrapper = DisplayUtils.convertToBitmapSprite( display.displayObject, null, 1, false, display.container );
			wrapper.sprite.x = spatial.x;
			wrapper.sprite.y = spatial.y;
			
			var origin:ColorTransform = display.displayObject.transform.colorTransform;		
			var white:ColorTransform = new ColorTransform( 1, 1, 1, 0, 0xFF, 0xFF, 0xFF );
			wrapper.sprite.transform.colorTransform = white;	
			
			this.whiteEntity = EntityUtils.createSpatialEntity( this.myGroup, wrapper.sprite, display.container );
			display = whiteEntity.get( Display );
			display.alpha = 0;

			var tween:Tween = new Tween();
			whiteEntity.add( tween );

			tween.to( display, 1.5, { alpha : 1, onComplete : fadeInPlayer, onCompleteParams : [ target, isPlayer ]});

		} //
		
		private function fadeInPlayer( target:Entity, isPlayer:Boolean ):void {

			var tween:Tween = this.whiteEntity.get( Tween );
			var display:Display = this.whiteEntity.get( Display );
			
			tween.to( display, 1.5, { alpha : 0 });
			
			tween = this.colorEntity.get( Tween );
			display = this.colorEntity.get( Display );
			tween.to( display, 1.5, { alpha : 1, onComplete : regainControl, onCompleteParams : [ target, isPlayer ]});

		} //

		private function regainControl( target:Entity, isPlayer:Boolean ):void {

			this.myGroup.removeEntity( this.whiteEntity );
			this.myGroup.removeEntity( this.colorEntity );

			var display:Display = target.get( Display ) as Display;
			display.alpha = 1;
			display.visible = true;

			if( isPlayer ) {

				SceneUtil.lockInput( this.myGroup, false, false );
			}

			if ( this.onTeleportIn ) {
				this.onTeleportIn();
			}

		} //

	} // class

} // package