package game.scenes.lands.shared.systems.weather {
	
	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	
	import engine.components.Camera;
	import engine.systems.CameraSystem;
	
	import game.scenes.lands.shared.LandGroup;
	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.classes.TileBitmapHits;
	import game.scenes.lands.shared.nodes.WeatherColliderNode;
	import game.scenes.lands.shared.tileLib.TileMap;
	
	public class LandSnowSystem extends WeatherSystemBase {
		
		private var colliderNodes:NodeList;
		
		/**
		 * for each column, this stores the y-value of the first filled tile that can block the snow.
		 * This is so snow computations don't have to be done every frame.
		 * The list is refreshed periodically.
		 * 
		 * topTileRows[ col ] = firstFilled-y-value;
		 */
		private var topTiles:Vector.<uint>;
		
		/**
		 * as the storm gets stronger, more snow is drawn.
		 */
		//private var snowCount:Number;
		
		/**
		 * shapes of snow that move around.
		 * each object has:  clip, vx, vy
		 */
		private var particles:Vector.<Object>;
		
		private var camera:Camera;
		
		/**
		 * snowDrift is the base x-velocity drift of snow.
		 * individual snow particles will have a a random amount added to this.
		 */
		private var snowDrift:Number;
		
		/**
		 * shape where the rain is drawn.
		 */
		private var snowClip:Sprite;
		
		/**
		 * using a separate shadeClip doesn't work unless you use a blur filter for the hard edges,
		 * and the blur filter is wayyyy too slow.
		 */
		//private var shadeClip:Shape;

		private var landGroup:LandGroup;
		private var tileHits:TileBitmapHits;

		/**
		 * count that prevents all the rain updates from happening on the same
		 * frame. players are marked as wet/dry, which tiles are wet, are marked on different frames.
		 */
		private var waitCount:int = 0;

		private var gameData:LandGameData;

		private var _fading:Boolean = false;

		public function LandSnowSystem( group:LandGroup ) {

			super();

			this.landGroup = group;

			this.gameData = group.gameData;
			this.tileHits = group.gameData.tileHits;

			this.initTopTiles( group.gameData );

		} //
		
		override public function update( time:Number ):void {
			
			this.updateSnow();
			
			if ( this.landGroup.gameEntity.sleeping || this.stopped ) {
				return;
			}
			
			if ( !this._fading ) {
				
				if ( this.particles.length < 80 && Math.random() < 0.2 ) {
					this.makeNewParticle();
				} //

			} else {
				
				if ( this.particles.length <= 0 ) {
					// stop snowing.
					this.stopped = true;
					//this.group.removeSystem( this, true );
					return;
				}
				
			} //
			
			var mod:int = waitCount++ % 6;
			var c:int;
			
			if ( mod == 0 ) {
				
				for( c = this.topTiles.length-1; c >= 0; c-- ) {
					
					// the +1 at the end ensures the initial tile itself gets covered with rain.
					this.topTiles[c] = 32*( this.tileHits.findTopFilled( c ) + 0.5 );
					
				} //
				
			} else if ( mod == 1 ) {

				for( var node:WeatherColliderNode = this.colliderNodes.head; node; node = node.next ) {

					c = ( node.spatial.x - this.gameData.mapOffsetX )/32;

					if ( c >= this.topTiles.length || c < 0 ) {
						continue;
					}

					if ( node.spatial.y <= this.topTiles[c] ) {

						// player is in the snow.
						if ( !node.collider.isHit ) {
							node.collider.isHit = true;
							node.collider.saveRegen = node.life.regenRate;
							node.life.regenRate = 0;		// no rengeration. TO-DO: scale this with the intensity of the rain.
						}
						
					} else {
						
						// player is not in the snow.
						if ( node.collider.isHit ) {
							node.collider.isHit = false;
							node.life.regenRate = node.collider.saveRegen;
						}
						
					} //
					
				} // for-loop.
				
			} // mod-test
			
		} // update()
		
		public function updateSnow():void {

			var x:Number, y:Number, maxY:Number;
			var c:int;		// snow column.

			var snow:Object;
			var clip:Shape;

			/**
			 * motion of the viewport of the camera. the camera viewport coordinates have moved in this direction
			 * since last frame.
			 */
			var camera_dx:Number = this.camera.targetDeltaX;
			var camera_dy:Number = this.camera.targetDeltaY;

			for ( var i:int = this.particles.length-1; i >= 0; i-- ) {

				snow = this.particles[i];
				clip = snow.clip;

				clip.x += snow.vx;
				clip.y += snow.vy;

				y = clip.y;
				x = clip.x;

				if ( camera_dx >= 0 ) {

					// camera-viewport is moving right. snow on the left side needs to loop.
					if ( x < this.camera.viewport.x-36 ) {

						if ( this._fading ) {
							this.removeSnow( i );
						} else {
							clip.x = camera.viewport.right - camera_dx*Math.random();
						}
						continue;

					} //

				} else {

					// camera moving left. snow on right wraps around.
					if ( x > this.camera.viewport.right+36 ) {
						if ( this._fading ) {
							this.removeSnow( i );
						} else {
							clip.x = camera.viewport.left - camera_dx*Math.random();
						}
						continue;
					} //

				} //

				if  ( camera_dy > 0 ) {

					// camera is moving down scene.
					if ( y < (this.camera.viewport.y-camera_dy-36) ) {

						if ( this._fading ) {
							this.removeSnow( i );
						} else {

							// actually need a test here to make sure the snow isn't underground.
							clip.y = this.camera.viewport.bottom - camera_dy*Math.random();

						}
						continue;
					}

				} else {

					// camera is moving upwards or staying still.
					if ( y > this.camera.viewport.bottom+36 ) {

						if ( this._fading ) {
							this.removeSnow( i );
						} else if ( camera_dy == 0 ) {
							clip.y = this.camera.viewport.top - 2 - 36*Math.random();
						} else {
							clip.y = this.camera.viewport.top - camera_dy*Math.random();
						}

						continue;

					}

				} //

				// check for snow under the terrain.
				c = ( x - this.gameData.mapOffsetX ) / 32;
				if ( c < 0 || c >= this.topTiles.length ) {
					// offscreen, somehow.
					continue;
				}
				if ( y > this.topTiles[c] ) {

					if ( camera_dx != 0 && Math.random() < 0.5 ) {

						// if the camera_dx is not zero, then snow might have vanished by running into
						// land horizontally.
						if ( camera_dx > 0 ) {
							clip.x = camera.viewport.right + 64 - ( camera_dx )*Math.random();
						} else {
							clip.x = camera.viewport.left - 64 - ( camera_dx )*Math.random();
						} //

						clip.y = this.camera.viewport.y + this.camera.viewportHeight*Math.random();

					} else if ( camera_dy > 0 ) {
						clip.y = this.camera.viewport.y - 64 - camera_dy*Math.random();
						clip.x = this.camera.viewport.x + Math.random()*this.camera.viewport.width;

					} else {
						clip.y = this.camera.viewport.y - 64 - camera_dy*Math.random();
						clip.x = this.camera.viewport.x + Math.random()*this.camera.viewport.width;
					} //

				}

				// test for actual hit of the snow particle against bitmap.
				/*if ( !this.tileHits.isEmpty( x + this.gameData.mapOffsetX, clip.y ) ) {
					// snow hit something. put it offscreen again.
					clip.y = this.camera.viewport.top - 2 - 38*Math.random();
					clip.x = this.camera.viewport.x + Math.random()*this.camera.viewport.width;
				} //*/

			} // for-loop.

		} // updateSnow()

		override public function fade():void {

			this._fading = true;

		} //

		private function removeSnow( index:int ):void {
			
			this.snowClip.removeChildAt( index );
			
			if ( index < this.particles.length-1 ) {
				this.particles[index] = this.particles.pop();
			} else {
				this.particles.pop();
			}
			
		} //
		
		private function makeNewParticle():void {
			
			var o:Object = new Object();
			var s:Shape = new Shape();
			
			var g:Graphics = s.graphics;
			g.beginFill( 0xFFFFFF );
			g.drawCircle( 0, 0, 2 + 2*Math.random() );
			
			s.x = this.camera.viewport.left + Math.random()*this.camera.viewportWidth;
			s.y = this.camera.viewport.top - 4;
			
			o.vx = this.snowDrift - 1 + 2*Math.random();
			o.vy = 1 + 2*Math.random();
			o.clip = s;

			this.particles.push( o );
			this.snowClip.addChild( s );
			
		} //
		
		/**
		 * 
		 */
		private function initTopTiles( gd:LandGameData ):void {
			
			var sampleMap:TileMap = gd.tileMaps["trees"];
			
			this.topTiles = new Vector.<uint>( sampleMap.cols, true );
			
			for( var i:int = this.topTiles.length-1; i >= 0; i-- ) {
				
				this.topTiles[i] = 0;
				
			} //
			
		} //
		
		private function nodeRemoved( node:WeatherColliderNode ):void {
			
			if ( node.collider.isHit ) {
				node.collider.isHit = false;
				node.life.regenRate = node.collider.saveRegen;
			}
			
		} //
		
		override public function addToEngine( systemManager:Engine):void {
			
			this.snowDrift = -1 + 2*Math.random();
			
			this.particles = new Vector.<Object>();
			
			var parentClip:DisplayObjectContainer = this.landGroup.curScene.hitContainer;
			
			this.snowClip = new Sprite();
			this.weatherClip = this.snowClip;
			this.snowClip.mouseChildren = this.snowClip.mouseEnabled = false;
			
			// do this so the snow is already aligned to the tile maps.
			//this.snowClip.x = this.gameData.mapOffsetX;
			//this.snowClip.x = -10;
			parentClip.addChild( this.snowClip );
			
			this.colliderNodes = systemManager.getNodeList( WeatherColliderNode );
			this.colliderNodes.nodeRemoved.add( this.nodeRemoved );
			
			this.camera = ( this.group.getSystem( CameraSystem ) as CameraSystem ).camera;
			
		} //
		
		override public function removeFromEngine( systemManager:Engine ):void {
			
			if ( this.snowClip && this.snowClip.parent ) {

				this.snowClip.parent.removeChild( this.snowClip );
				this.snowClip = null;

			}
			
			this.particles.length = 0;
			
			// remove all rain colliders.
			for( var node:WeatherColliderNode = this.colliderNodes.head; node; node = node.next ) {
				node.entity.remove( WeatherColliderNode );			// don't need these now.
			} //
			
			systemManager.releaseNodeList( WeatherColliderNode );
			
			this.colliderNodes = null;
			
		} //
		
	} // class
	
} // package