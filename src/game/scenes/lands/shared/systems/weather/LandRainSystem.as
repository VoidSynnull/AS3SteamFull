package game.scenes.lands.shared.systems.weather {
	
	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.display.Shape;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Audio;
	import engine.components.Camera;
	import engine.managers.SoundManager;
	import engine.systems.CameraSystem;
	
	import game.data.sound.SoundModifier;
	import game.scene.SceneSound;
	import game.scenes.lands.shared.LandGroup;
	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.classes.TileBitmapHits;
	import game.scenes.lands.shared.nodes.WeatherColliderNode;
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.util.AudioUtils;
	
	public class LandRainSystem extends WeatherSystemBase {
		
		private const rainSoundURL:String = "rain_light_loop.mp3";
		private const thunderSoundURL:String = "thunder.mp3";
		
		private var colliderNodes:NodeList;
		
		/**
		 * for each column, this stores the index of the row for the first non-empty tile
		 * that can block rain.  This is so rain computations don't have to be done every frame.
		 * The list will be refreshed periodically.
		 * 
		 * topTileRows[ col ] = firstFilledRow;
		 */
		private var blockedTilesY:Vector.<Number>;
		
		/**
		 * as the rain gets stronger, more rain is drawn.
		 */
		private var rainStrength:Number;
		
		//private var rainTotalTime:Number;
		//private var rainCurrentTime:Number;
		
		private var camera:Camera;
		
		/**
		 * shape where the rain is drawn.
		 */
		private var rainClip:Shape;
		
		/**
		 * using a separate shadeClip doesn't work unless you use a blur filter for the hard edges.
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
		
		/**
		 * rain can't slant more than 32 in the x-direction or it will fall over on the next tile.
		 */
		private var maxRainSlant:Number = 32
		private var _rainColor:uint;
		/*public function set rainColor( color:uint ):void {
		this._rainColor = color;
		}*/
		
		private var _rainAlpha:Number = 0.2;
		public function set rainAlpha( alpha:Number ):void {
			this._rainAlpha = alpha;
		}
		
		/**
		 * a stupid quick fix for now to allow acid rain. in the future we might want
		 * to be able to define all kinds of different rain effects.
		 * fire rain, life rain.. who knows? then we'd need a more complex system.
		 */
		private var isAcidRain:Boolean;
		
		private var rainStarted:Boolean = false;
		private var _fading:Boolean = false;
		
		public function LandRainSystem( group:LandGroup, rainColor:uint=0xFFFFFF, isAcid:Boolean=false ) {
			
			super();
			
			this.landGroup = group;
			
			this._rainColor = rainColor;
			this.isAcidRain = isAcid;
			
			this.gameData = group.gameData;
			this.tileHits = group.gameData.tileHits;
			
			this.initTopTiles( group.gameData );
			
		} //
		
		override public function update( time:Number ):void {
			
			// make it rain.
			this.drawRain();
			
			if ( this.landGroup.gameEntity.sleeping || this.stopped ) {
				return;
			}
			
			if ( !this._fading ) {
				
				if ( this.rainStrength < 26 ) {
					
					if ( !this.rainStarted && this.rainStrength > 12 ) {
						this.rainStarted = true;
						AudioUtils.play( this.group , SoundManager.AMBIENT_PATH + this.rainSoundURL, 1, true,
							[SoundModifier.FADE, SoundModifier.MUSIC] );
					}
					
					this.rainStrength += 0.01;
					
				} else {
					
					// a very small chance of thunder.
					if ( Math.random() < 0.005 ) {
						AudioUtils.play( this.group, SoundManager.AMBIENT_PATH + this.thunderSoundURL, 1, false, SoundModifier.EFFECTS );
					}
					
				}
				
			} else {
				
				this.rainStrength -= 0.04;
				if ( this.rainStrength <= 2 ) {
					// stop raining.
					this.stopped = true;
					//this.group.removeSystem( this, true );
					return;
				}
				
			} //
			
			var mod:int = waitCount++ % 7;
			var c:int;
			
			if ( mod == 0 ) {
				
				for( c = this.blockedTilesY.length-1; c >= 0; c-- ) {
					
					// the +1 at the end ensures the initial tile itself gets covered with rain.
					this.blockedTilesY[c] = this.tileHits.findTopY( ( c+0.5)*32 + this.gameData.mapOffsetX );
					//this.shadeRain();
					
				} //
				
			} else if ( mod == 1 ) {
				
				for( var node:WeatherColliderNode = this.colliderNodes.head; node; node = node.next ) {
					
					c = ( node.spatial.x - this.gameData.mapOffsetX )/32;
					if ( c >= this.blockedTilesY.length || c < 0 ) {
						continue;
					}
					
					if ( node.spatial.y <= this.blockedTilesY[c] ) {
						
						if ( this.isAcidRain && node.entity == this.landGroup.getPlayer() ) {
							
							node.collider.isHit = true;
							node.life.drainHit( this.rainStrength*3.5*time );
							
						} else {
							
							// player is in the rain.
							if ( !node.collider.isHit ) {
								
								node.collider.isHit = true;
								// this if-check could be outside the loop...
								node.collider.saveRegen = node.life.regenRate;
								node.life.regenRate = 0;		// no rengeration. TO-DO: scale this with the intensity of the rain.
								
								//trace( "NOW IN THE RAIN" );
								
							}
							
						} // acid-rain test.
						
					} else {
						
						// player is not in the rain.
						if ( node.collider.isHit ) {
							
							node.collider.isHit = false;
							
							if ( !this.isAcidRain ) {
								node.life.regenRate = node.collider.saveRegen;
							}
						}
						
					} // player-in-rain test
					
				} // for-loop.
				
			} // mod-test
			
		} // update()
		
		public function drawRain():void {
			
			var g:Graphics = this.rainClip.graphics;
			var x:Number, maxY:Number;
			
			// Jordan's (modified) rain code:
			g.clear();
			
			// only use this code if not using a separate shade clip:
			/*g.beginFill( 0, this.rainStrength/100 );
			g.drawRect( 0, 0, this.camera.viewportWidth + 20, this.camera.viewportHeight+8 );
			g.endFill();*/
			
			g.lineStyle( 1.1, this._rainColor, this._rainAlpha );
			
			var c:int;		// rain column.
			
			for ( var i:int = 1; i <= this.rainStrength; i++ ) {
				
				x = Math.random()*this.camera.viewportWidth;
				
				c = ( x + this.camera.viewportX - this.gameData.mapOffsetX ) / 32;
				if ( c >= this.blockedTilesY.length ) {
					continue;
				}
				
				// need to convert from max rain row to scene-y value to overlay y-value.
				maxY = this.blockedTilesY[c] - this.camera.viewportY;
				if ( maxY < 0 ) {
					continue;
				}
				maxY = (maxY/2)*( 1 + Math.random() );
				
				g.moveTo( x, maxY );
				g.lineTo( x + this.maxRainSlant, maxY-1200 );
				
			} // for-loop.
			
		} //
		
		/**
		 * test/debugging shader puts an alpha fill in areas with active rainfall.
		 */
		/*public function shadeRain():void {
		
		var g:Graphics = this.shadeClip.graphics;
		var x:Number, y:Number;
		
		g.clear();
		
		g.beginFill( 0, this.rainStrength/100 );
		g.moveTo( 0, 0 );
		
		x = 32*this.topTiles.length;
		
		g.lineTo( x, 0 );
		
		for( var c:int = this.topTiles.length-1; c >= 0; c-- ) {
		
		y = 32*this.topTiles[c];
		g.lineTo( x, y );
		x -= 32;
		g.lineTo( x, y );
		
		} //
		
		g.endFill();
		
		} //*/
		
		/*private function updateTopTiles():void {
		for( var i:int = this.topTileRows.length-1; i >= 0; i-- ) {
		this.topTileRows[i] = this.tileHits.findTopFilled( i );
		} //
		
		} //*/
		
		override public function fade():void {
			
			this._fading = true;
			var sndEntity:Entity = this.group.getEntityById( SceneSound.SCENE_SOUND );
			if ( !sndEntity ) {
				return;
			}
			
			var audio:Audio = sndEntity.get( Audio ) as Audio;
			if ( !audio ) {
				return;
			}
			
			// begin rain fade-out.
			audio.fade( this.rainSoundURL, 0 );
			
		} //
		
		/**
		 * 
		 */
		private function initTopTiles( gd:LandGameData ):void {
			
			var sampleMap:TileMap = gd.tileMaps["trees"];
			
			this.blockedTilesY = new Vector.<Number>( sampleMap.cols, true );
			
			for( var i:int = this.blockedTilesY.length-1; i >= 0; i-- ) {
				
				this.blockedTilesY[i] = 0;
				
			} //
			
		} //
		
		private function nodeRemoved( node:WeatherColliderNode ):void {
			
			if ( node.collider.isHit ) {
				node.collider.isHit = false;
				node.life.regenRate = node.collider.saveRegen;
			}
			
		} //
		
		override public function addToEngine( systemManager:Engine):void {

			this.rainStrength = 1;
			
			//var overlay:DisplayObjectContainer = this.landGroup.mainScene.hitContainer;
			var parentClip:DisplayObjectContainer = this.landGroup.curScene.overlayContainer;
			
			this.rainClip = new Shape();
			this.weatherClip = this.rainClip;
			
			// do this so drawing the rain is already aligned to the tile maps.
			//this.rainClip.x = this.gameData.mapOffsetX;
			//this.rainClip.x;
			parentClip.addChildAt( this.rainClip, 0 );
			
			/*parentClip = this.landGroup.mainScene.hitContainer;
			this.shadeClip = new Shape();
			this.shadeClip.x = this.gameData.mapOffsetX;
			// the blur filter is impossible: it slows the game SEVERELY. leaving this note here so I never try it again.
			//this.shadeClip.filters = [ new BlurFilter() ];
			
			parentClip.addChildAt( this.shadeClip, 0 );*/
			
			this.colliderNodes = systemManager.getNodeList( WeatherColliderNode );
			this.colliderNodes.nodeRemoved.add( this.nodeRemoved );
			
			this.camera = ( this.group.getSystem( CameraSystem ) as CameraSystem ).camera;
			
		} //
		
		override public function removeFromEngine( systemManager:Engine ):void {

			if ( this.rainClip && this.rainClip.parent ) {
				
				this.rainClip.parent.removeChild( this.rainClip );
				this.rainClip = null;
				
			}
			/*if ( this.shadeClip && this.shadeClip.parent ) {
			
			this.shadeClip.parent.removeChild( this.shadeClip );
			this.shadeClip = null;
			
			} //*/

			AudioUtils.stop( this.group, this.rainSoundURL );

			// remove all rain colliders.
			for( var node:WeatherColliderNode = this.colliderNodes.head; node; node = node.next ) {
				node.entity.remove( WeatherColliderNode );			// don't need these now.
			} //
			
			systemManager.releaseNodeList( WeatherColliderNode );
			
			this.colliderNodes = null;
			
		} //
		
	} // class
	
} // package