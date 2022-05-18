package game.scenes.lands.shared.systems.weather {
	
	/**
	 * this class just randomly turns different weather and meteorological features on and off
	 * it doesn't do any real processing in itself.
	 */
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.scene.template.CameraGroup;
	import game.scenes.lands.shared.LandGroup;
	import game.scenes.lands.shared.components.LandMeteor;
	import game.scenes.lands.shared.components.LandWeatherCollider;
	import game.scenes.lands.shared.nodes.LifeNode;
	import game.scenes.lands.shared.systems.LandMeteorSystem;
	import game.scenes.lands.shared.world.BiomeWeatherType;
	import game.systems.SystemPriorities;
	import game.util.AudioUtils;
	
	public class RealmsWeatherSystem extends System {
		
		/**
		 * when a weather system is added, the corresponding components
		 * have to be added to all characters so they can react to that type of weather.
		 * they don't have these components by default since weather is relatively rare.
		 */
		private var charNodes:NodeList;
		
		private var waitCount:int;
		
		private var gameEntity:Entity;
		
		/**
		 * weathers available for current biome.
		 */
		private var activeWeathers:Vector.<BiomeWeatherType>;
		
		/**
		 * weather system currently active.
		 */
		private var curWeatherSystem:WeatherSystemBase;
		
		/**
		 * time until the current weather is finished.
		 */
		private var weatherTime:Number;
		private var weatherStopping:Boolean;
		
		private var cameraGroup:CameraGroup;
		
		public function RealmsWeatherSystem() {
			
			super();
			
		} //
		
		override public function update( time:Number ):void {
			
			if ( this.curWeatherSystem != null ) {
				
				this.weatherTime -= time;
				if ( this.weatherTime <= 0 ) {

					if ( !this.weatherStopping ) {

						this.fadeOutWeather();

					} else if ( this.curWeatherSystem.stopped ) {

						// weather effect has completely ended.
						this.stopWeather();

					} //

				} else {
					var target:Number = this.cameraGroup.zoomTarget;
					var clip:DisplayObject = this.curWeatherSystem.getWeatherClip();
					if ( clip != null ) {
						if ( target != 1 ) {
							clip.alpha -= 0.01;
						} else {
							clip.alpha += ( 1 - clip.alpha ) / 4;
						} //
					}
				}
				
			} //
			
			if ( --this.waitCount > 0 ) {
				// only check for weather changes every few seconds.
				// these system-changes aren't really time-critical.
				return;
			} //
			this.waitCount = 120;
			
			if ( this.gameEntity.sleeping ) {
				return;
			}
			
			var weather:BiomeWeatherType;
			for( var i:int = this.activeWeathers.length-1; i >= 0; i-- ) {
				
				weather = this.activeWeathers[i];
				// since rate is chance per second, and the waitCount blocks for about 2 seconds...
				if ( Math.random() < 2*weather.rate ) {
					
					switch( weather.type ) {
						
						case "rain":
							this.startRain();
							break;
						case "sandstorm":
							this.startSandstorm();
							break;
						case "meteor":
							this.startMeteor();
							break;
						case "snow":
							this.startSnow();
							break;
						case "acid":
							this.startAcidRain();
							break;
						
					} //
					
					break;
					
				} //
				
			} //
			
		} // update()

		public function hideWeather():void {

			if ( this.curWeatherSystem == null ) {
				return;
			}
			this.curWeatherSystem.getWeatherClip().visible = false;

		} //

		public function showWeather():void {

			if ( this.curWeatherSystem == null ) {
				return;
			}
			this.curWeatherSystem.getWeatherClip().visible = true;

		} //

		/**
		 * biome changed. cancel current weather.
		 */
		private function onBiomeChanged():void {
			
			if ( this.curWeatherSystem != null ) {
				this.group.removeSystem( this.curWeatherSystem );
				this.curWeatherSystem = null;
			}
			
		} //
		
		/*public function onSceneZoomIn():void {
		
		if ( this.curWeatherSystem == null ) {
		return;
		}
		
		var clip:DisplayObject = this.curWeatherSystem.getWeatherClip();
		TweenUtils.globalTo( this.group, clip, 1, {alpha:1} );
		
		} //
		
		public function onSceneZoomOut():void {
		
		if ( this.curWeatherSystem == null ) {
		return;
		}
		
		var clip:DisplayObject = this.curWeatherSystem.getWeatherClip();
		TweenUtils.globalTo( this.group, clip, 1, {alpha:0} );
		
		
		} //*/
		
		public function fadeOutWeather():void {
			
			this.weatherStopping = true;
			this.curWeatherSystem.fade();

		} //

		/**
		 * this could be dangerous if the system already removed itself?
		 */
		public function stopWeather():void {
			
			if ( this.curWeatherSystem != null ) {

				this.group.removeSystem( this.curWeatherSystem );
				this.curWeatherSystem = null;
				this.weatherStopping = false;

			} //
			
		} //
		
		private function setCurWeather( sys:WeatherSystemBase ):void {
			
			this.curWeatherSystem = sys;
			this.weatherStopping = false;
			
			this.weatherTime = 40 + 40*Math.random();
			
			this.group.addSystem( sys, SystemPriorities.update );
			
			for( var node:LifeNode = this.charNodes.head; node; node = node.next ) {
				
				if ( node.entity.get( LandWeatherCollider ) == null ) {
					node.entity.add( new LandWeatherCollider(), LandWeatherCollider );
				}
				
			} //
			
		} //
		
		public function startRain():void {
			
			if ( this.curWeatherSystem != null ) {
				return;
			}
			
			this.setCurWeather( new LandRainSystem( this.group as LandGroup ) );
			
		} //
		
		public function startAcidRain():void {
			
			if ( this.curWeatherSystem != null ) {
				return;
			}
			
			var rainSystem:LandRainSystem = new LandRainSystem( this.group as LandGroup, 0xbbe25e, true );
			rainSystem.rainAlpha = 0.7;
			
			this.setCurWeather( rainSystem );
			
		} //
		
		public function startSandstorm():void {
			
			if ( this.curWeatherSystem != null ) {
				return;
			}
			
			this.setCurWeather( new SandStormSystem( this.group as LandGroup ) );
			
		} //
		
		public function startSnow():void {
			
			if ( this.curWeatherSystem != null ) {
				return;
			}
			
			this.setCurWeather( new LandSnowSystem( this.group as LandGroup ) );
			
		} //
		
		public function startMeteor():void {
			
			var land:LandGroup = this.group as LandGroup;
			
			if ( !land.worldMgr.curRealm.hasSavedData( land.worldMgr.curLoc.x ) ) {
				this.group.shellApi.loadFile( ( this.group as LandGroup ).sharedAssetURL + "meteor.swf", this.onMeteorLoaded );
			}
			
		} //
		
		private function onMeteorLoaded( meteor:MovieClip ):void {
			
			AudioUtils.play( this.group, SoundManager.EFFECTS_PATH + "object_fall_01.mp3" );
			meteor.gotoAndStop( 1 );
			meteor.mouseChildren = meteor.mouseEnabled = false;
			
			var art:MovieClip = meteor.art;
			art.gotoAndStop( 1 + Math.floor( Math.random()*meteor.totalFrames ) );
			art.mouseEnabled = false;
			art.mouseChildren = false;
			
			// this motion component is 'heavy' for such a simple component. might not even use it.
			var motion:Motion = new Motion();
			motion.velocity.x = -360 + 720*Math.random();
			motion.velocity.y = 200 + 100*Math.random();
			motion.acceleration.y = 200;
			
			var e:Entity = new Entity()
				.add( new Spatial( Math.random()*( this.group as LandGroup ).sceneBounds.width, 0 ), Spatial )
				.add( new LandMeteor( true ), LandMeteor )
				.add( new Display( meteor, ( this.group as LandGroup ).curScene.hitContainer ), Display )
				.add( motion, Motion );
			
			this.systemManager.addEntity( e );
			
			if ( this.systemManager.getSystem( LandMeteorSystem ) == null ) {
				
				// no meteor system currently active.
				this.group.addSystem( new LandMeteorSystem(), SystemPriorities.update );
				
			}
			
		} //
		
		/**
		 * if a char is added while the system is in progress, the correct components
		 * for current weather conditions have to be added.
		 */
		private function onCharAdded( node:LifeNode ):void {
			
			if ( this.systemManager.getSystem(LandRainSystem) != null ) {
				
				node.entity.add( new LandWeatherCollider(), LandWeatherCollider );
				
			} //
			
		} //
		
		override public function addToEngine( systemManager:Engine):void {
			
			this.waitCount = 0;
			
			( this.group as LandGroup ).onBiomeChanged.add( this.onBiomeChanged );
			
			// might replace this with something more char-specific.
			this.charNodes = systemManager.getNodeList( LifeNode );
			this.charNodes.nodeAdded.add( this.onCharAdded );
			
			this.gameEntity = ( this.group as LandGroup ).gameEntity;
			this.activeWeathers = ( this.group as LandGroup ).gameData.biomeData.weatherTypes;
			
			this.cameraGroup = this.group.getGroupById( CameraGroup.GROUP_ID ) as CameraGroup;
			
		}
		
		override public function removeFromEngine( systemManager:Engine ):void {
			
			( this.group as LandGroup ).onBiomeChanged.remove( this.onBiomeChanged );

			this.curWeatherSystem = null;
	
			this.charNodes.nodeAdded.remove( this.onCharAdded );
			this.charNodes = null;
			
		} //
		
	} // class
	
}

// package