package game.scenes.lands.shared.systems.weather {
	
	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
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
	
	public class SandStormSystem extends WeatherSystemBase {
		
		private const stormSoundURL:String = "desert_01_loop.mp3";
		
		private var colliderNodes:NodeList;
		
		/**
		 * stores the location of the last coordinate that gets hit by the storm.
		 * topTileRows[ row ] = firstFilledX;
		 * the first-filled-X is the first filled X coordinate when coming from the
		 * current direction of the storm - left or right.
		 */
		private var blockedTiles:Vector.<Number>;
		
		private var camera:Camera;
		
		/**
		 * shape where the storm is drawn.
		 */
		private var sandClip:Sprite;
		
		/**
		 * positive means the storm is moving from left to right.
		 * negative means the storm is moving from right to left.
		 */
		private var stormDirection:int = 1;
		
		private var landGroup:LandGroup;
		
		private var tileHits:TileBitmapHits;
		
		/**
		 * count that prevents all the rain updates from happening on the same
		 * frame. players are marked as wet/dry, which tiles are wet, are marked on different frames.
		 */
		private var waitCount:int = 0;
		
		private var gameData:LandGameData;
		
		/**
		 * shapes of snow that move around.
		 * each object has:  clip, vx, vy
		 */
		private var particles:Vector.<Object>;
		
		/**
		 * storm can't slant more than 32 pixels or lines will start to fall into neighboring (possibly blocked) tiles.
		 */
		private var maxStormSlant:Number = 8
		private var stormColor:uint = 0xe6c7aa;
		private var stormAlpha:Number = 0.1;
		
		private var _started:Boolean = false;
		private var _fading:Boolean = false;
		
		private var accelerationPt:Point;
		
		public function SandStormSystem( group:LandGroup ) {
			
			super();
			
			this.landGroup = group;
			
			this.gameData = group.gameData;
			this.tileHits = group.gameData.tileHits;
			
			this.initBlockedTiles( group.gameData );
			
		} //
		
		override public function update( time:Number ):void {
			
			this.updateParticles();
			
			if ( this.landGroup.gameEntity.sleeping || this.stopped ) {
				return;
			}
			
			if ( !this._fading ) {
				
				if ( this.particles.length < 60 && Math.random() < 0.2 ) {
					this.makeNewParticle();
				} //
				
				if ( !this._started ) {
					
					this._started = true;
					AudioUtils.play( this.group , SoundManager.AMBIENT_PATH + this.stormSoundURL, 1, true,
						[SoundModifier.FADE, SoundModifier.MUSIC] );
					
				}
				
			} else {
				
				if ( this.particles.length == 0 ) {
					this.stopped = true;
				//	this.group.removeSystem( this, true );
					return;
				}
				
			} //
			
			var mod:int = waitCount++ % 5;
			var r:int;
			var c:int;
			
			for( var node:WeatherColliderNode = this.colliderNodes.head; node; node = node.next ) {
				
				r = ( node.spatial.y )/32;
				if ( r >= this.blockedTiles.length || r < 0 ) {
					// very rare. this would mean the player is partly offscreen.
					continue;
				}
				
				if ( (this.stormDirection > 0 && node.spatial.x <= this.blockedTiles[r])
					|| (this.stormDirection < 0 && node.spatial.x >= this.blockedTiles[r]) ) {
					
					node.motion.parentAcceleration = this.accelerationPt;
					
				} else {
					
					// might need to undo the acceleration?
					
				} //
				
			} // for-loop.
			
			if ( mod == 0 ) {
				
				for( r = this.blockedTiles.length-1; r >= 0; r-- ) {
					
					this.blockedTiles[r] = this.tileHits.findBlockedX( r, this.stormDirection );
					
				} //
				
			}
			
		} // update()
		
		public function updateParticles():void {
			
			// these are in local scene coordinates.
			var x:Number, y:Number, maxY:Number;
			var c:int;		// snow column.
			
			var particle:Object;
			var clip:Shape;
			
			/**
			 * motion of the viewport of the camera. the camera viewport coordinates have moved in this direction
			 * since last frame.
			 */
			var camera_dx:Number = this.camera.targetDeltaX;
			var camera_dy:Number = this.camera.targetDeltaY;
			
			var view:Rectangle = this.camera.viewport;
			
			for ( var i:int = this.particles.length-1; i >= 0; i-- ) {
				
				particle = this.particles[i];
				clip = particle.clip;
				
				clip.x += particle.vx;
				clip.y += particle.vy;
				
				y = clip.y;
				x = clip.x;
				
				if ( x < view.x-48 ) {
					
					if ( this._fading ) {
						this.removeParticle( i );
					} else {
						if ( this.stormDirection > 0 ) {
							clip.x = view.x - 10 - 10*Math.random();
						} else {
							clip.x = view.right + ( 32 - camera_dx )*Math.random();
						} //
						clip.y = view.top + Math.random()*view.height;
						
					}
					continue;
					
				} else if ( x > view.right+48 ) {
					
					if ( this._fading ) {
						this.removeParticle( i );
					} else {
						clip.x = view.x + ( -32 - camera_dx )*Math.random();
					}
					clip.y = view.top + Math.random()*view.height;
					continue;
					
				} //
				
				if  ( camera_dy > 0 ) {
					
					// camera is moving down scene.
					if ( y < (view.y-camera_dy-36) ) {
						
						if ( this._fading ) {
							this.removeParticle( i );
						} else {
							
							// actually need a test here to make sure the sand isn't underground?
							clip.y = view.bottom - camera_dy*Math.random();
							
						}
						continue;
					}
					
				} else {
					
					// camera is moving upwards or staying still.
					if ( y > view.bottom+36 ) {
						
						if ( this._fading ) {
							this.removeParticle( i );
						} else if ( camera_dy == 0 ) {
							clip.y = view.top - 2 - 36*Math.random();
						} else {
							clip.y = view.top - camera_dy*Math.random();
						}
						
						continue;
						
					}
					
				} //
				
				//if ( !this.tileHits.isEmpty( x, y ) ) {
				if ( y < 0 ) {
					continue;
				} else if ( y > view.bottom ) {
					continue;
				} else if ( this.stormDirection > 0 ) {
					
					if ( x > this.blockedTiles[ Math.floor( y/ 32) ] ) {
						
						clip.y = view.y + view.width*Math.random();
						clip.x = view.x - 32 - 16*Math.random();
						
					}
					
				} else {
					
					if ( x < this.blockedTiles[ Math.floor( y/ 32 ) ] ) {
						clip.y = view.top + view.width*Math.random();
						clip.x = view.right + 32 + 16*Math.random();
					}
					
				} // ( stormDirection < 0 )
				
			} // for-loop.
			
		} // updateSnow()
		
		override public function fade():void {
			
			this._fading = true;
			
		} //
		
		/*public function drawSandLines():void {
		
		var g:Graphics = this.sandClip.graphics;
		var y:Number;
		// hitX is the X coordinate where the wind is expected to first hit the land.
		var hitX:Number;
		
		// Jordan's (modified) rain code:
		g.clear();
		
		// only use this code if not using a separate shade clip:
		//g.beginFill( 0, this.stormStrength/100 );
		//g.drawRect( 0, 0, this.camera.viewportWidth + 20, this.camera.viewportHeight+8 );
		//g.endFill();
		
		g.lineStyle( 20, this.stormColor, this.stormAlpha );
		
		var r:int, i:int;		// storm row
		
		if ( this.stormDirection > 0 ) {
		
		for ( i = 1; i <= this.stormStrength; i++ ) {
		
		y = Math.random()*this.camera.viewportHeight;
		
		r = ( y + this.camera.viewportY ) / 32;
		if ( r >= this.blockedTiles.length ) {
		continue;
		}
		
		hitX = this.blockedTiles[r] - this.camera.viewportX;
		if ( hitX < 0 ) {
		continue;
		}
		hitX = (hitX/2)*( 1 + Math.random() );
		
		g.moveTo( hitX, y );
		g.lineTo( hitX-1200, y + this.maxStormSlant*( 2*Math.random() - 1 ) );
		
		} // for-loop.
		
		} else {
		
		// lines come from the right.
		for ( i = 1; i <= this.stormStrength; i++ ) {
		
		y = Math.random()*this.camera.viewportHeight;
		
		r = ( y + this.camera.viewportY ) / 32;
		if ( r >= this.blockedTiles.length ) {
		continue;
		}
		
		hitX = this.blockedTiles[r] - this.camera.viewportX;
		
		if ( hitX > this.camera.viewport.width ) {
		continue;
		} else if ( hitX < 0 ) {
		hitX = 0;
		}
		//hitX = hitX - Math.random();
		
		g.moveTo( hitX, y );
		g.lineTo( hitX+1200, y + this.maxStormSlant*( 2*Math.random() - 1 ) );
		
		} // for-loop.
		
		} //
		
		} //*/
		
		private function removeParticle( index:int ):void {
			
			this.sandClip.removeChildAt( index );
			
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
			
			var size:Number;
			
			if ( Math.random() < 0.7 ) {
				
				size = 0.12 + 0.1*Math.random();
				g.beginFill( this.stormColor, 1 - size );
				g.drawCircle( 0, 0, 1 + 10*size );
				
				o.vx = this.stormDirection*( 16 + 16*Math.random() );
				
			} else {
				
				// bigger sand.
				size = 0.06 + 0.92*Math.random();
				g.beginFill( this.stormColor, 0.6*(1 - size) );
				g.drawCircle( 0, 0, 1 + 36*size );
				
				o.vx = this.stormDirection*( 24 + 12*Math.random() );
				
			}
			
			s.x = -4;
			s.y = this.camera.viewport.top + Math.random()*this.camera.viewportHeight;
			
			o.vy = -1 + 2*Math.random();
			o.clip = s;
			
			this.particles.push( o );
			this.sandClip.addChild( s );
			
		} //
		
		private function beginStopStorm():void {
			
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
			audio.fade( this.stormSoundURL, 0 );
			
		} //
		
		/**
		 * 
		 */
		private function initBlockedTiles( gd:LandGameData ):void {
			
			var sampleMap:TileMap = gd.tileMaps["trees"];
			
			this.blockedTiles = new Vector.<Number>( sampleMap.rows, true );
			
			for( var i:int = this.blockedTiles.length-1; i >= 0; i-- ) {
				
				this.blockedTiles[i] = 0;
				
			} //
			
		} //
		
		private function nodeRemoved( node:WeatherColliderNode ):void {
			
			if ( node.collider.isHit ) {
				node.collider.isHit = false;
				node.life.regenRate = node.collider.saveRegen;
			}
			
		} //
		
		override public function addToEngine( systemManager:Engine):void {
			
			this.particles = new Vector.<Object>();
			
			if ( Math.random() < 0.5 ) {
				this.stormDirection = 1;
			} else {
				this.stormDirection = -1;
			}
			
			this.accelerationPt = new Point( 3600*this.stormDirection, 0 );
			
			var parentClip:DisplayObjectContainer = this.landGroup.curScene.hitContainer;
			//var parentClip:DisplayObjectContainer = this.landGroup.mainScene.overlayContainer;
			
			this.sandClip = new Sprite();
			this.weatherClip = this.sandClip;
			this.sandClip.mouseChildren = this.sandClip.mouseEnabled = false;
			
			this.sandClip.x = 0;
			parentClip.addChildAt( this.sandClip, 0 );
			
			this.colliderNodes = systemManager.getNodeList( WeatherColliderNode );
			this.colliderNodes.nodeRemoved.add( this.nodeRemoved );
			
			this.camera = ( this.group.getSystem( CameraSystem ) as CameraSystem ).camera;
			
		} //
		
		override public function removeFromEngine( systemManager:Engine ):void {
			
			if ( this.sandClip && this.sandClip.parent ) {
				
				this.sandClip.parent.removeChild( this.sandClip );
				this.sandClip = null;
				
			}
			
			AudioUtils.stop( this.group, this.stormSoundURL );
			
			// remove all rain colliders.
			for( var node:WeatherColliderNode = this.colliderNodes.head; node; node = node.next ) {
				
				if ( node.motion.parentAcceleration == this.accelerationPt ) {
					node.motion.parentAcceleration = null;
				}
				
				node.entity.remove( WeatherColliderNode );			// don't need these now.
			} //
			
			systemManager.releaseNodeList( WeatherColliderNode );
			
			this.colliderNodes = null;
			
		} //
		
	} // class
	
} // package