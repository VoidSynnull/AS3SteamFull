package game.scenes.virusHunter.joesCondo.util {

	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.collider.BitmapCollider;
	import game.components.entity.collider.ClimbCollider;
	import game.components.entity.collider.HazardCollider;
	import game.components.entity.collider.PlatformCollider;
	import game.components.entity.collider.SceneCollider;
	import game.components.entity.collider.WaterCollider;
	import game.components.entity.collider.ZoneCollider;
	import game.components.hit.CurrentHit;
	import game.components.motion.MotionTarget;
	import game.creators.ui.ToolTipCreator;
	import game.util.CharUtils;

	public class SimpleUtils {

		static public function makeUIBtn( btn:DisplayObjectContainer, onClick:Function, g:Group=null, visible:Boolean=true, onKey:Function=null ):Entity {
			
			var e:Entity = new Entity()
				.add( new Display( btn, null, visible ), Display )
				.add( new Spatial( btn.x, btn.y ), Spatial );
			
			var events:Array = [ InteractionCreator.CLICK ];
			if ( onKey != null ) {
				events.push( InteractionCreator.KEY_DOWN );
			}
			
			var i:Interaction = InteractionCreator.addToEntity( e, events, btn );
			i.click.add( onClick );
			
			if ( onKey ) {
				i.keyDown.add( onKey );
			}

			if ( g ) {
				g.addEntity( e );
				ToolTipCreator.addToEntity( e );
			}
			
			return e;
			
		} //

		/**
		 * Button that responds to both mousedown, mouseup ( release outside also handled )
		 */
		static public function makeUpDownBtn( g:Group, btn:DisplayObjectContainer, onDown:Function, onUp:Function ):Entity {

			var e:Entity = new Entity()
				.add( new Display( btn, null, false ), Display )
				.add( new Spatial( btn.x, btn.y ), Spatial );
			
			var i:Interaction = InteractionCreator.addToEntity( e, [ InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.RELEASE_OUT ], btn );
			i.down.add( onDown );
			i.up.add( onUp );
			i.releaseOutside.add( onUp );
			
			g.addEntity( e );
			ToolTipCreator.addToEntity( e );
			
			return e;
			
		} //

		static public function manualSay( char:Entity, say_id:String, callback:Function=null ):void {

			var dialog:Dialog = char.get( Dialog );
			if ( dialog == null ) {

				if ( callback ) {
					callback( null );		// the callback should actually be dialog data.
				}
				return;

			} //

			if ( callback ) {
				dialog.complete.addOnce( callback );
			}
			dialog.sayById( say_id );

		} //

		/**
		 * Bitmap a clip currently visible on the stage.
		 */
		public static function bitmapStageClip( displayObject:DisplayObject, transparent:Boolean=true, fill:Number=0 ):BitmapData {
			
			var offsetMatrix : Matrix = displayObject.transform.matrix;
			var displayObjectBounds:Rectangle = displayObject.getBounds( displayObject.parent );
			
			if ( displayObject.rotation != 0 )  {
				transparent = true;			// rotated clip must have transparency or it will get a black fill.
			}
			
			offsetMatrix.tx = -( displayObjectBounds.left - displayObject.x );
			offsetMatrix.ty = -( displayObjectBounds.top - displayObject.y );
			
			var bitmapData : BitmapData = new BitmapData( displayObjectBounds.width, displayObjectBounds.height, transparent, fill);
			bitmapData.draw( displayObject, offsetMatrix );
			
			return( bitmapData );
			
		} //

		static public function hideEntity( e:Entity ):void {

			var display:Display = e.get( Display );
			if ( display ) {
				display.visible = false;
			}

		} //

		// hide npc or player and stop all its movement things.
		static public function hideChar( char:Entity ):void {

			var display:Display = char.get( Display );
			if ( display ) {
				display.visible = false;
			}

			var sleep:Sleep = char.get( Sleep );
			if ( sleep ) {
				sleep.ignoreOffscreenSleep = true;
				sleep.sleeping = true;
			}

			CharUtils.lockControls( char, true );

		} //

		static public function showChar( char:Entity, ignoreOffscreenSleep:Boolean=false ):void {

			var display:Display = char.get( Display );
			if ( display ) {
				display.visible = true;
			}
			
			var sleep:Sleep = char.get( Sleep );
			if ( sleep ) {
				char.ignoreGroupPause = true;
				sleep.ignoreOffscreenSleep = ignoreOffscreenSleep;
				sleep.sleeping = false;
			}

			CharUtils.lockControls( char, false );

		} //

		static public function removeColliders( char:Entity ):void {

			char.remove( SceneCollider );
			char.remove( PlatformCollider );
			char.remove( ClimbCollider );
			char.remove( WaterCollider );
			char.remove( BitmapCollider );
			char.remove( ZoneCollider );
			char.remove( CurrentHit );
			char.remove( HazardCollider);

		} //

		static public function setPosition( char:Entity, x:Number, y:Number ):void {

			var spatial:Spatial = char.get( Spatial ) as Spatial;
			spatial.x = x;
			spatial.y = y;

			var mt:MotionTarget = char.get( MotionTarget ) as MotionTarget;

			if ( mt ) {
				mt.targetX = x;
				mt.targetY = y;
			}

		} //

		static public function disableSleep( char:Entity ):void {

			var sleep:Sleep = char.get( Sleep );
			sleep.ignoreOffscreenSleep = true;
			sleep.sleeping = false;

		} //

		static public function enableSleep( char:Entity ):void {
			
			var sleep:Sleep = char.get( Sleep );
			sleep.ignoreOffscreenSleep = false;
			sleep.sleeping = false;
			
		} //

		static public function makeBoxEntity( x:Number, y:Number, width:Number, height:Number, parent:DisplayObjectContainer=null ):Entity {

			var s:Sprite = new Sprite();
			s.graphics.beginFill( 0, 1 );
			s.graphics.drawRect( -width/2, -height/2, width, height );
			s.graphics.endFill();

			/**
			 * these boxes are meant for clicks, hittests, etc. so you won't usually want to see the box.
			 */
			var d:Display = new Display( s );
			d.alpha = 0;

			if ( parent ) {
				parent.addChild( s );
			}

			var e:Entity = new Entity()
				.add( d, Display )
				.add( new Spatial(x,y), Spatial );

			return e;

		} //

		public function writeBits( n:int ):String {

			var bit:int = 31;
			var s:String = "";

			do {
		
				if ( n & ( 1 << bit-- ) ) {
					s += "1";
				} else {
					s += "0";
				} //
		
			} while ( bit >= 0 );

			return s;

		} //

	} // End EntityUtils
	
} // End package