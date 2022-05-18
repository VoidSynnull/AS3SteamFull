package game.scenes.survival1.shared
{	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.group.Group;
	import engine.util.Command;
	
	import game.components.ParticleMovement;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.hit.CurrentHit;
	import game.components.motion.ShakeMotion;
	import game.components.scene.Cold;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ButtonCreator;
	import game.data.animation.entity.character.Tremble;
	import game.data.scene.characterDialog.DialogData;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.shrink.mainStreet.StreamerSystem.Streamer;
	import game.scenes.shrink.mainStreet.StreamerSystem.StreamerSystem;
	import game.scenes.survival1.Survival1Events;
	import game.scenes.survival1.cave.Cave;
	import game.scenes.survival1.cliffside.Cliffside;
	import game.scenes.survival1.hillside.Hillside;
	import game.scenes.survival1.knollside.Knollside;
	import game.scenes.survival1.shared.components.SurvivalWind;
	import game.scenes.survival1.shared.components.ThermostatGaugeComponent;
	import game.scenes.survival1.shared.components.WindBlock;
	import game.scenes.survival1.shared.components.WindFlag;
	import game.scenes.survival1.shared.components.WindFlagScale;
	import game.scenes.survival1.shared.popups.FirePopup;
	import game.scenes.survival1.shared.systems.SurvivalWindSystem;
	import game.scenes.survival1.shared.systems.ThermostatSystem;
	import game.scenes.survival1.shared.systems.WindFlagScaleSystem;
	import game.scenes.survival1.shared.systems.WindFlagSystem;
	import game.scenes.survival1.woods.Woods;
	import game.systems.ParticleMovementSystem;
	import game.systems.SystemPriorities;
	import game.systems.hit.ItemHitSystem;
	import game.systems.motion.ShakeMotionSystem;
	import game.ui.elements.DialogPicturePopup;
	import game.ui.showItem.ShowItem;
	import game.util.CharUtils;
	import game.util.DataUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.SkinUtils;
	
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class SurvivalScene extends PlatformerGameScene
	{
		private static const SURVIVAL_HUD:String = 'scenes/survival1/shared/hud.swf';
		private var thermostat:Entity
		private var fireStarter:Entity;
		private var windFlag:Entity;
		private var flag:Entity;
		private var fireAsset:MovieClip;
		private var _events:Survival1Events;
		private var cabbageLoop:int = 0;
		
		// minimum performance level to include effects
		private var flagQualityLevel:int = PerformanceUtils.QUALITY_HIGHEST;//too intensive for mobile in general
		private var snowQualityLevel:int = PerformanceUtils.QUALITY_HIGHEST;// until we can better determine how pwerful devices are
		private var enviornmentQualityLevel:int = PerformanceUtils.QUALITY_HIGH;
		
		// find quality levels for these devices
		//iphone5 100, ipad3 = 50, ipad2 && ipad mini = 40, iphone4 = 20, ipod touch 4th gen = 0
		
		public function SurvivalScene()
		{
			super();
		}
		
		override public function loaded():void
		{
			_events = super.events as Survival1Events;
			
			super.loaded();
			if(shellApi.sceneName == "Cave")
				removeEntity(flag);
			else
			{
				/*
				We don't want snow to be falling in the Cave, but we still want the thermostat and FirePopup button
				we get from a SurvivalScene.
				
				There are also no leaves iciles or branches to be added either
				*/
				player.add(new WindBlock());
				viewportEmitter();
				addChildGroup(new EnviornmentInteractions(this, _hitContainer, player, enviornmentQualityLevel));
			}
			
			addSystem( new ShakeMotionSystem(), SystemPriorities.move );
			
			var itemHitSystem:ItemHitSystem = super.getSystem(ItemHitSystem) as ItemHitSystem;
			
			if(itemHitSystem)
			{
				itemHitSystem.gotItem.removeAll();
				itemHitSystem.gotItem.add( handleGotItem );
			}
		}
		
		protected function handleGotItem( item:Entity ):void
		{			
			var itemID:String = item.get(Id).id;
			if( itemID.indexOf("handbook") != 0 )
			{
				if( itemID == _events.NEST || itemID == _events.LOGS || itemID == _events.MITTENS || itemID == _events.DRY_KINDLING || 
					itemID == _events.WET_KINDLING || itemID == _events.STRIKER )
				{
					if( !fireStarter )
					{
						addFireHud();
					}
				}
				
				if( itemID == _events.FLINT )
				{
					removeEntity( this.getEntityById( "flintSparkle" ));
					if( !fireStarter )
					{
						addFireHud();
					}
				}
				
				super.shellApi.getItem( itemID, null, true );
			}
				
			else
			{
				super.shellApi.getItem( itemID, null, true );
				getSurvivalPage( itemID );
			}
		}
		
		protected override function addUI( container:Sprite ):void
		{	
			shellApi.loadFile( shellApi.assetPrefix + SURVIVAL_HUD, Command.create(addSurvivalHud, container) );
		}
		
		public var wind:SurvivalWind;
		
		private function viewportEmitter():void
		{
			wind = new SurvivalWind(new Rectangle(0,0,shellApi.camera.viewportWidth, shellApi.camera.viewportHeight),1,15, 800, 200, 100,0,snowQualityLevel);
			var entity:Entity;
			if(wind.ignoreMe)
			{
				entity = EntityUtils.createSpatialEntity(this,new MovieClip());
				entity.add(wind).add(new Audio());
			}
			else
			{
				var emitter:Emitter2D = wind.wind;
				
				entity = EmitterCreator.create(this, overlayContainer, emitter);
				entity.add(wind).add(new ParticleMovement()).add( new Id( "wind" )).add( new Audio());
				
				DisplayUtils.moveToBack(entity.get(Display).displayObject);
				
				emitter.start();
				emitter.runAhead(30);
			}
			if(PerformanceUtils.qualityLevel >= flagQualityLevel)
			{
				removeEntity(flag);
				
				var spatial:Spatial = windFlag.get(Spatial);
				
				var flagHeight:Number = 32;
				
				var clip:MovieClip = new MovieClip();
				
				var post:MovieClip = Display(windFlag.get(Display)).displayObject;
				
				var knots:MovieClip = post["knots"];
				
				clip.y = -post.height + flagHeight / 2 + 8;
				
				entity = EntityUtils.createSpatialEntity(this, clip, post);
				DisplayUtils.moveToBack(entity.get(Display).displayObject);
				entity.add(new WindFlag(wind, player.get(WindBlock))).add(new Streamer(clip,90,null,false, 2, 2, 1, 4, 20, flagHeight, 0, 0x3EC961));
				DisplayUtils.moveToBack(entity.get(Display).displayObject);
				
				DisplayUtils.moveToOverUnder(clip, post, false);
				
				addSystem(new StreamerSystem());
				addSystem(new WindFlagSystem());
			}
			else
			{
				//much simpler flag system
				flag.add(new WindFlag(wind, player.get(WindBlock),1.5)).add(new WindFlagScale()).add(new Sleep(false, true));
				addSystem(new WindFlagScaleSystem());
			}
			
			addSystem(new SurvivalWindSystem());
			if(!wind.ignoreMe)
				addSystem(new ParticleMovementSystem(this));
		}
		/**
		 *     SURVIVAL HUD
		 * 	FIRE STARTER POPUP
		 *     THERMOMETER
		 */
		private function addSurvivalHud( asset:MovieClip, container:Sprite ):void
		{
			var spatial:Spatial;
			var entity:Entity;
			var interaction:Interaction;
			var textField:TextField;
			var gauge:ThermostatGaugeComponent = new ThermostatGaugeComponent();
			var shakeMotion:ShakeMotion;
			var system:ThermostatSystem;
			
			var currentTemperature:Number = shellApi.getUserField( (super.events as Survival1Events).TEMPERATURE_FIELD, shellApi.island) as Number;
			
			asset.thermostat.mouseEnabled = false;
			asset.thermostat.mouseChildren = false;
			thermostat = EntityUtils.createSpatialEntity( this, asset.thermostat, super.overlayContainer );
			spatial = thermostat.get( Spatial );
			spatial.scale *= .725;
			spatial.x = 10;
			spatial.y = super.shellApi.viewportHeight - 10;
			DisplayUtils.moveToBack(thermostat.get(Display).displayObject);
			
			entity = EntityUtils.createSpatialEntity( this, asset.thermostat.bar );
			spatial = entity.get( Spatial );
			
			shakeMotion = new ShakeMotion( new RectangleZone( -1, -1, 1, 1 ));
			shakeMotion.active = false;
			thermostat.add( new SpatialAddition()).add( shakeMotion );
			
			gauge.maskSpatial = spatial;
			gauge.shakeMotion = shakeMotion;
			gauge.blueLiquidDisplayObject = asset.thermostat.blueLiquid;
			gauge.blueOrbDisplayObject = asset.thermostat.blueOrb;
			gauge.redLiquidDisplayObject = asset.thermostat.redLiquid;
			gauge.redOrbDisplayObject = asset.thermostat.redOrb;
			
			if( shellApi.checkEvent( _events.BEGIN_LANDING ))
			{
				gauge.active = true;
			}
			
			player.add( gauge ).add( new Cold());
			
			system = new ThermostatSystem(); 
			system.frozen.addOnce( freeze );
			system.shiver.addOnce( shiver );
			
			if ( !DataUtils.isNull( currentTemperature ))
			{
				if( currentTemperature == 0 || !shellApi.checkEvent( _events.BEGIN_LANDING ))
				{
					currentTemperature = 98.6;
				}
				
				if( !shellApi.checkEvent( _events.FROZE ))
				{
					gauge.temperature = currentTemperature;
					gauge.maskSpatial.scaleY = currentTemperature / 100;
					gauge.redLiquidDisplayObject.alpha = gauge.maskSpatial.scaleY;
					gauge.redOrbDisplayObject.alpha = gauge.maskSpatial.scaleY;
				}
					
				else
				{
					shellApi.removeEvent( _events.FROZE );
					gauge.temperature = 98.6;
					gauge.maskSpatial.scaleY = .986;
					
					shellApi.setUserField( (super.events as Survival1Events).TEMPERATURE_FIELD, gauge.temperature, shellApi.island);
				}
			}
			else
			{
				shellApi.removeEvent( _events.FROZE );
				gauge.temperature = 98.6;
				gauge.maskSpatial.scaleY = .986;
				
				shellApi.setUserField( (super.events as Survival1Events).TEMPERATURE_FIELD, gauge.temperature, shellApi.island);
			}
			
			Display( thermostat.get( Display )).container.setChildIndex( Display( thermostat.get( Display )).displayObject, 0 );
			
			fireAsset = asset.fire;
			fireAsset.x = 65;
			fireAsset.y = super.shellApi.viewportHeight - 10;
			
			asset.windFlag.mouseEnabled = false;
			asset.windFlag.mouseChildren = false;
			windFlag = EntityUtils.createSpatialEntity(this, asset.windFlag, overlayContainer);
			DisplayUtils.moveToBack( windFlag.get( Display ).displayObject );
			
			var flagSpatial:Spatial = windFlag.get(Spatial);
			flagSpatial.x = fireAsset.x + fireAsset.width + asset.windFlag.width;
			flagSpatial.y = fireAsset.y - 10;
			
			flag = EntityUtils.createSpatialEntity(this, asset.flag, overlayContainer);
			BitmapTimelineCreator.convertToBitmapTimeline(flag, asset.flag);
			Timeline(flag.get(Timeline)).play();
			spatial = flag.get(Spatial);
			spatial.x = flagSpatial.x;
			spatial.y = flagSpatial.y - flagSpatial.height + spatial.height / 2 + 12;
			
			DisplayUtils.moveToBack(flag.get(Display).displayObject);
			
			if( shellApi.checkHasItem( _events.MITTENS ) || shellApi.checkHasItem( _events.DRY_KINDLING ) || shellApi.checkHasItem( _events.WET_KINDLING ) || 
				shellApi.checkHasItem( _events.FLINT ) || shellApi.checkHasItem( _events.NEST ) || shellApi.checkHasItem( _events.LOGS ) || shellApi.checkHasItem( _events.STRIKER ))
			{	
				fireStarter = ButtonCreator.createButtonEntity( fireAsset, this, launchFirePopup, super.overlayContainer );
				
				interaction = fireStarter.get( Interaction );
				interaction.click.add( launchFirePopup );
				DisplayUtils.moveToBack( fireStarter.get( Display ).displayObject );
				Display( fireStarter.get( Display )).container.setChildIndex( Display( fireStarter.get( Display )).displayObject, 0 );
			}
			else
			{
				fireAsset.visible = false;
			}
			
			addSystem( system, SystemPriorities.move );
			super.addUI( container );
		}
		
		override public function destroy():void
		{
			if(player)
			{
				var thermostatComponent:ThermostatGaugeComponent = player.get(ThermostatGaugeComponent);
				if(thermostatComponent.active)
				{
					shellApi.setUserField( (super.events as Survival1Events).TEMPERATURE_FIELD, thermostatComponent.temperature, shellApi.island);
				}
			}
			
			super.destroy();
		}
		
		/**
		 *     FAILED TO KEEP TEMPERATURE HIGH ENOUGH
		 */
		private function shiver():void
		{
			var gauge:ThermostatGaugeComponent = player.get( ThermostatGaugeComponent );
			gauge.active = false;
			
			CharUtils.setAnim( player, Tremble, false, 150 );
			
			var dialog:Dialog = player.get( Dialog );
			dialog.sayById( "freezing" );
			
			dialog.complete.addOnce( setCold );
		}
		
		private function setCold( dialogData:DialogData ):void
		{	
			SkinUtils.setSkinPart( player, SkinUtils.MOUTH, "Angry", false );
			SkinUtils.setSkinPart( player, SkinUtils.EYE_STATE, "Open", false );
			
			var gauge:ThermostatGaugeComponent = player.get( ThermostatGaugeComponent );
			gauge.active = true;
		}
		
		private function freeze():void
		{
			shellApi.completeEvent( _events.FROZE );
			var freezePopup:DialogPicturePopup = new DialogPicturePopup(overlayContainer);
			freezePopup.updateText("oh no! you've gotten too cold. time to start over!", "try again");
			freezePopup.configData("freezePopup.swf", "scenes/survival1/shared/freezePopup/");
			freezePopup.removed.add(resetScene);
			addChildGroup(freezePopup);
		}
		
		private function resetScene(group:Group):void
		{
			switch( shellApi.sceneName.toLowerCase())
			{
				case "cave":
					shellApi.loadScene( Cave );
					break;
				
				case "cliffside":
					shellApi.loadScene( Cliffside );
					break;
				
				case "hillside":
					shellApi.loadScene( Hillside );
					break;
				
				case "knollside":
					shellApi.loadScene( Knollside );
					break;
				
				case "woods":
					shellApi.loadScene( Woods );
					break;
			}
		}
		
		/**
		 *    FIRE STARTER POPUP
		 */
		private function launchFirePopup( entity:Entity ):void
		{
			/*
			If you're in the Cave and you try opening the FirePopup, the "noise" you make
			awakens the bear and you have to retry.
			*/
			
			var currentHit:CurrentHit = player.get( CurrentHit );
			var dialog:Dialog = player.get( Dialog );
			var motion:Motion = player.get( Motion );
			
			if(this.shellApi.sceneName == "Cave")
			{
				this.shellApi.triggerEvent(_events.FIRE_AWAKENED_BEAR);
			}
				/*
				Otherwise, you're outside and we're gonna check for where the wind is blowing.
				*/
				
			else if( currentHit.hit )
			{
				var groundId:Id = currentHit.hit.get( Id );
				if( motion.velocity.x == 0 && motion.velocity.y == 0 )
				{
					if( !(groundId.id == "snow" || groundId.id == "ground" || groundId.id == "baseGround" ))
					{
						dialog.sayById( "not_here" );
					}
						
					else
					{
						/*
						If the wind is blowing left, windX = -1.
						If the wind is blowing right, windX = 1;
						If you're protected from the wind, windX = 0.
						*/
						var windX:int;
						
						if(this.shellApi.checkEvent(_events.IN_FIRE_ZONE))
						{
							if(this.shellApi.checkEvent(_events.BOULDER_IN_POSITION))
							{
								windX = 0;
							}
							else
							{
								windX = -1;
							}
						}
						else windX = this.wind.windVelocity > 0 ? 1 : -1;
						
						this.addChildGroup(new FirePopup(this.overlayContainer, windX ));
					}
				}
			}
		}
		
		private function addFireHud():void
		{
			var interaction:Interaction;
			
			fireStarter = ButtonCreator.createButtonEntity( fireAsset, this, launchFirePopup, super.overlayContainer );
			
			interaction = fireStarter.get( Interaction );
			interaction.click.add( launchFirePopup );
			DisplayUtils.moveToBack( fireStarter.get( Display ).displayObject );
			Display( fireStarter.get( Display )).container.setChildIndex( Display( fireStarter.get( Display )).displayObject, 0 );
			
			fireAsset.visible = true;
		}
		
		/**
		 *     HANDLER FOR SURVIVAL GUIDE PAGES
		 */
		
		private function getSurvivalPage( item:String ):void
		{
			var showItem:ShowItem = super.getGroupById( ShowItem.GROUP_ID ) as ShowItem;
			if( !showItem )
			{
				showItem = new ShowItem();
				addChildGroup( showItem );
			}
			
			showItem.transitionComplete.addOnce( Command.create( cleanUpPageLogic, item ));
		}
		
		private function cleanUpPageLogic( item:String ):void
		{
			if( !shellApi.checkHasItem( _events.HANDBOOK_PAGES ))
			{
				shellApi.getItem( _events.HANDBOOK_PAGES, null, false );
			}
			
			shellApi.removeItem( item );
		}
	}
}