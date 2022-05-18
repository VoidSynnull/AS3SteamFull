package game.scenes.lands.shared.util {

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.display.IBitmapDrawable;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.components.entity.character.Skin;
	import game.components.hit.MovieClipHit;
	import game.components.hit.Zone;
	import game.scenes.lands.shared.components.InputManager;
	import game.scenes.lands.shared.components.LandCollectible;
	import game.scenes.lands.shared.components.LightningStrike;
	import game.scenes.lands.shared.components.SimpleWave;
	import game.scenes.lands.shared.groups.LandUIGroup;
	import game.scenes.lands.shared.tileLib.tileTypes.TileType;
	import game.components.entity.VariableTimeline;

	/**
	 * utility class for creating entities and stuff needed for land. I guess.
	 */

	public class LandUtils {

		static public function makeZone( group:Group, parent:DisplayObjectContainer, name:String, x:int, y:int, width:int, height:int ):Entity {

			var s:Sprite = new Sprite();
			s.graphics.beginFill( 0, 1 );
			s.graphics.drawRect( 0, 0, width, height );
			s.graphics.endFill();
			s.x = x;
			s.y = y;
			s.mouseChildren = s.mouseEnabled = false;

			parent.addChild( s );

			var d:Display = new Display( s );
			d.alpha = 0;

			var e:Entity = new Entity()
				.add( d, Display )
				.add( new Spatial( x, y ), Spatial )
				.add( new Id( name ), Id )
				.add( new Zone(), Zone );

			group.addEntity( e );

			return e;

		} //

		/**
		 * Register a button using the lands InputManager and SharedToolTip
		 */
		static public function makeTipButton( btn:DisplayObjectContainer, group:LandUIGroup, onClick:Function ):void {
		
			if ( btn is MovieClip ) {
				( btn as MovieClip ).gotoAndStop( 1 );
			}
			group.inputManager.addEventListener( btn, MouseEvent.CLICK, onClick );
			group.sharedTip.addClipTip( btn );

		} //

		static public function destroyTipButton( btn:DisplayObjectContainer, group:LandUIGroup ):void {

			group.inputManager.removeListeners( btn );
			group.sharedTip.removeToolTip( btn );

		} //

		/**
		 * Register a button using the lands InputManager with an optional key listener.
		 */
		static public function makeUIBtn( btn:DisplayObjectContainer, group:LandUIGroup,
										  onClick:Function, onKey:Function=null ):DisplayObjectContainer {

			if ( btn is MovieClip ) {
				( btn as MovieClip ).gotoAndStop( 1 );
			}

			if ( onKey != null ) {
				group.inputManager.addEventListener( btn.stage, KeyboardEvent.KEY_DOWN, onKey );
			}
			group.inputManager.addEventListener( btn, MouseEvent.CLICK, onClick );

			// add tool tip.

			return btn;

		} //

		static public function destroyUIButton( btn:DisplayObjectContainer, group:LandUIGroup ):void {

			group.inputManager.removeListeners( btn );

		} //

		/**
		 * Button that responds to both mousedown, mouseup ( release outside also handled )
		 */
		static public function makeUpDownBtn( btn:DisplayObjectContainer, input:InputManager, onDown:Function, onUp:Function ):DisplayObjectContainer {

			input.addEventListener( btn, MouseEvent.MOUSE_DOWN, onDown );
			input.addEventListener( btn, MouseEvent.MOUSE_UP, onUp );
			input.addEventListener( btn, MouseEvent.RELEASE_OUTSIDE, onUp );

			btn.visible = false;		// start invisible.
			
			return btn;
			
		} //

		static public function makeClipCollectible( clip:MovieClip, g:Group, spatial:Spatial, collectible:LandCollectible,
														parentClip:DisplayObjectContainer ):Entity {

			clip.mouseChildren = false;
			clip.mouseEnabled = false;
			clip.gotoAndStop( 1 );

			var tl:VariableTimeline = new VariableTimeline( false );
			tl.playing = true;
			tl.onTimelineEnd.add( LandUtils.enableClipCollection );

			parentClip.addChild( clip );

			var e:Entity = new Entity()
				.add( new Display( clip ), Display )
				.add( collectible, LandCollectible )
				.add( new SimpleWave( Math.PI, 0, 8 ), SimpleWave )
				.add( tl, VariableTimeline )
				.add( spatial, Spatial );

			g.addEntity( e );
			
			return e;

		} //

		static public function makeBitmapCollectible( g:Group, spatial:Spatial, collectible:LandCollectible, parentClip:DisplayObjectContainer ):Entity {
			
			var s:Sprite = new Sprite();
			var b:Bitmap = new Bitmap( collectible.type.bitmap );
			b.x = -b.width/2;
			b.y = -b.height/2;
			
			s.mouseChildren = false;
			s.mouseEnabled = false;
			
			s.addChild( b );
			
			parentClip.addChild( s );
			
			var e:Entity = new Entity()
				.add( new Display( s ), Display )
				.add( collectible, LandCollectible )
				.add( new SimpleWave( Math.PI, 0, 8 ), SimpleWave )
				//.add( new BitmapCollider(), BitmapCollider )
				//.add( new CurrentHit(), CurrentHit )
				// might need PlatformCollider, SceneCollider?
				//.add( new Motion(), Motion )
				.add( spatial, Spatial );
			
			/*InteractionCreator.addToEntity( e, [ InteractionCreator.CLICK ] );
			
			var si:SceneInteraction = new SceneInteraction();
			e.add( si, SceneInteraction );*/
			
			var hit:MovieClipHit = new MovieClipHit( "tileItem", "player" );
			e.add( hit, MovieClipHit );
			
			g.addEntity( e );
			
			return e;
			
		} //

		/**
		 * dont make a poptanium clip collectible until the timeline is done.
		 */
		static public function enableClipCollection( e:Entity, tl:VariableTimeline ):void {

			var hit:MovieClipHit = new MovieClipHit( "tileItem", "player" );
			e.add( hit, MovieClipHit );

			e.remove( VariableTimeline );

		} //

		static public function makeTileTypeClip( tileType:TileType, size:int, circle:Boolean=true ):Sprite {

			var s:Sprite = new Sprite();
			var g:Graphics = s.graphics;

			// outline.
			g.lineStyle( 2, 0, 0.5 );

			if ( tileType.image != null ) {

				// tileType.image might not be a bitmap - so need a prepare function to return it as a bitmap if it is one,
				// or else draw it into a new bitmap.
				var b:BitmapData = LandUtils.prepareBitmap( tileType.image, size, size );
				g.beginBitmapFill( b );

			} else {

				g.beginFill( 0 );			// temp

			} //
			
			if ( circle ) {
				g.drawCircle( 0, 0, size );
			} else {
				g.drawRect( 0, 0, size, size );
			} //

			g.endFill();

			return s;

		} //

		static public function makeBitmapCircle( b:BitmapData, radius:int, drawX:Number=0, drawY:Number=0 ):Sprite {

			var s:Sprite = new Sprite();
			var g:Graphics = s.graphics;
		
			// draw an outline.
			g.lineStyle( 2, 0, 0.5 );

			g.beginBitmapFill( b );
			g.drawCircle( drawX, drawY, radius );
			g.endFill();

			return s;

		} //

		/**
		 * xDraw,yDraw give the local upper-left corner of the rect (within the drawing sprite)
		 */
		static public function makeBitmapRect( b:BitmapData, size:Number, xDraw:Number=0, yDraw:Number=0 ):Sprite {
			
			var s:Sprite = new Sprite();
			var g:Graphics = s.graphics;

			// draw an outline.
			g.lineStyle( 2, 0, 0.5 );

			g.beginBitmapFill( b );
			g.drawRect( xDraw, yDraw, size, size );
			g.endFill();

			return s;

		} //

		/**
		 * Returns bitmapData if ib is a Bitmap, or else returns the bitmapData itself if ib is a BitmapData
		 * for anything else, it returns a bitmap of the given dimensions, with ib drawn into it.
		 */
		static public function prepareBitmap( ib:IBitmapDrawable, width:int=2, height:int=2 ):BitmapData {

			var bmd:BitmapData;

			if ( ib is Bitmap ) {

				return ( ib as Bitmap ).bitmapData;

			} else if ( ib is BitmapData ) {
				
				return ( ib as BitmapData );

			} else if ( ib is DisplayObject ) {

				var d:DisplayObject = ib as DisplayObject;
				// need this for resizing so the icons arent drawn with blank patches on the right/bottom sides.
				//var bnds:Rectangle = d.getBounds( d );

				var mat:Matrix = new Matrix( 1, 0, 0, 1, 0, 0 );

				// images will never be scaled up.
				if ( d.width > width ) {
					mat.a = (width/d.width);
				} else if ( d.width < width ) {
					mat.tx = ( width - d.width)/2;
				} //
				
				if ( d.height > height ) {
					mat.d = (height/d.height);
				} else if ( d.height < height ) {
					mat.ty = (height - d.height)/2;
				}

				var ds:Number;
				if ( mat.a < mat.d ) {

					// x-scaling smaller than y-scaling
					/**
					 * the height has now scaled more than it needs to in order to fit in the box, so it will be squished to the top of the icon.
					 * compute the difference between its old scaled height and its new smaller scaled height, and move it forward by half, to center it.
					 */
					ds = height - mat.a*d.height;
					mat.d = mat.a;
					mat.ty = ds/2;

				} else if ( mat.d < mat.a ) {

					ds = width - mat.d*d.width;
					mat.a = mat.d;
					mat.tx = ds/2;

				} //

				bmd = new BitmapData( width, height, true, 0 );
				bmd.draw( d, mat );

				return bmd;

			} //

			// dont think there are any types of ibitmapdrawable left. hyuck.
			bmd = new BitmapData( width, height, true, 0 );
			bmd.draw( ib );

			return bmd;

		} //

		static public function getDrawBitmap( dest:BitmapData, ib:IBitmapDrawable, width:int=2, height:int=2 ):BitmapData {
			
			var bmd:BitmapData;
			
			if ( ib is Bitmap ) {
				
				return ( ib as Bitmap ).bitmapData;

			} else if ( ib is BitmapData ) {
				
				return ( ib as BitmapData );
				
			} else if ( ib is DisplayObject ) {

				var d:DisplayObject = ib as DisplayObject;
				var mat:Matrix = new Matrix( 1, 0, 0, 1, 0, 0 );

				// images will never be scaled up - only down. no reason to waste bitmaps.
				if ( d.width > width ) {
					mat.a = (width/d.width);
				} else if ( d.width < width ) {
					mat.tx = ( width - d.width)/2;
				} //

				//var wide:int = (d.root.loaderInfo.width);

				if ( d.height > height ) {
					mat.d = (height/d.height);
				} else if ( d.height < height ) {
					mat.ty = (height - d.height)/2;
				}

				if ( mat.a < mat.d ) {

					// required x-scaling smaller than y-scaling. scale y down even more to match proportions.
					mat.d = mat.a;

					// the height has now scaled more than it needs to in order to fit in the box, so it will be squished to the top of the icon.
					// compute the difference between its old scaled height and its new smaller scaled height, and move it forward by half, to center it.
					mat.ty = ( height - mat.a*d.height )/2;

				} else if ( mat.d < mat.a ) {

					mat.a = mat.d;								// scale the width down even further to match.
					mat.tx = ( width - mat.a*d.width )/2;		// width - new scaled width.

				} //

				dest.draw( d, mat );

				return dest;

			} //

			return dest;

		} //

		/*static public function drawIconToBitmap( g:Graphics, dest:BitmapData, ib:IBitmapDrawable ):void {

			if ( ib is Bitmap ) {

				g.beginBitmapFill( (ib as Bitmap).bitmapData );

			} else if ( ib is BitmapData ) {
				
				g.beginBitmapFill( ib as BitmapData );

			} else if ( ib is DisplayObject ) {
				
				var d:DisplayObject = ib as DisplayObject;
				// need this for resizing so the icons arent drawn with blank patches on the right/bottom sides.
				//var bnds:Rectangle = d.getBounds( d );
				
				var mat:Matrix = new Matrix( 1, 0, 0, 1, 0, 0 );
				
				// images will never be scaled up.
				if ( d.width > dest.width ) {
					mat.a = (dest.width/d.width);
				}
				if ( d.height > dest.height ) {
					mat.d = (dest.height/d.height);
				}
				
				var ds:Number;
				if ( mat.a < mat.d ) {
					
					// x-scaling smaller than y-scaling
					// * the height has now scaled more than it needs to in order to fit in the box, so it will be squished to the top of the icon.
					// * compute the difference between its old scaled height and its new smaller scaled height, and move it forward by half, to center it.
					ds = dest.height - mat.a*d.height;
					mat.d = mat.a;
					mat.ty = ds/2;
					
				} else if ( mat.d < mat.a ) {
					
					ds = dest.width - mat.d*d.width;
					mat.a = mat.d;
					mat.tx = ds/2;
					
				} //

				dest.draw( d, mat );
				
			} //

			 //dont think there are any types of ibitmapdrawable left. hyuck.
			dest.draw( ib );

		} //*/

		/**
		 * add lightning strike component to an existing entity.
		 */
		static public function addLightningStrike( lightningEntity:Entity, char:Entity, lightningParent:DisplayObjectContainer,
			offsetX:int=-55, offsetY:int=28 ):void {

			var skin:Skin = char.get( Skin ) as Skin;
			var item:Entity = skin.getSkinPartEntity( "item" );

			if ( item == null ) {
				item = char;
				//trace( "NO ITEM FOUND?" );
			}

			var strike:LightningStrike = new LightningStrike( ( item.get( Display ) as Display ), lightningParent );
			strike.sourceOffsetX = offsetX;
			strike.sourceOffsetY = offsetY;

			strike.active = true;

			lightningEntity.add( strike, LightningStrike );

		} //

	} // class

} // package