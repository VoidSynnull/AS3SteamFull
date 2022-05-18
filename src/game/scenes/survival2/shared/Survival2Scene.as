package game.scenes.survival2.shared
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.text.TextField;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.group.Group;
	
	import game.components.motion.ShakeMotion;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.survival1.shared.components.ThermostatGaugeComponent;
	import game.scenes.survival1.shared.systems.ThermostatSystem;
	import game.scenes.survival1.shared.systems.TriggerHitSystem;
	import game.scenes.survival2.Survival2Events;
	import game.scenes.survival2.beaverDen.BeaverDen;
	import game.scenes.survival2.fishingHole.FishingHole;
	import game.scenes.survival2.shared.systems.HookSystem;
	import game.scenes.survival2.trees.Trees;
	import game.scenes.survival2.unfrozenLake.UnfrozenLake;
	import game.systems.SystemPriorities;
	import game.systems.motion.ShakeMotionSystem;
	import game.ui.elements.DialogPicturePopup;
	import game.ui.inventory.Inventory;
	import game.util.DataUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class Survival2Scene extends PlatformerGameScene
	{
		private static const SURVIVAL_HUD:String = 'scenes/survival2/shared/hud.swf';
		private var thermostat:Entity;
		private var _events:Survival2Events;
		
		public function Survival2Scene()
		{
			super();
		}
		
		override public function loaded():void
		{
			_events = super.events as Survival2Events;
			
			this.addSystem(new HookSystem());
			this.addSystem(new TriggerHitSystem());
			
			shellApi.eventTriggered.add(onEventTriggered);
			
			super.loaded();
			
		}
		
		private function onEventTriggered(event:String, init:Boolean, makeCurrent:Boolean, removeEvent:String):void
		{
			if(event == _events.UPDATE_POLE)
			{
				var inventory:Inventory = getGroupById(Inventory.GROUP_ID) as Inventory;
				inventory.removed.add(showFishingPoleUpdate);
			}
		}
		
		private function showFishingPoleUpdate(group:Group):void
		{
			shellApi.showItem(_events.FISHING_POLE,shellApi.island);
		}
		
		protected override function addUI( container:Sprite ):void
		{
			super.addUI( container );
			
			shellApi.loadFile( shellApi.assetPrefix + SURVIVAL_HUD, addSurvivalHud );
		}
		
		/**
		 *     SURVIVAL HUD
		 *     THERMOMETER
		 */
		private function addSurvivalHud( asset:MovieClip ):void
		{
			var spatial:Spatial;
			var display:Display;
			var entity:Entity;
			var interaction:Interaction;
			var textField:TextField;
			var gauge:ThermostatGaugeComponent = new ThermostatGaugeComponent();
			var shakeMotion:ShakeMotion;
			var system:ThermostatSystem;
			var tween:Tween = new Tween();
			
			var currentTemperature:Number = shellApi.getUserField((super.events as Survival2Events).TEMPERATURE_FIELD, shellApi.island) as Number;
			
			thermostat = EntityUtils.createSpatialEntity( this, asset.thermostat, super.overlayContainer );
			display = thermostat.get( Display );
			display.alpha = 0;
			spatial = thermostat.get( Spatial );
			spatial.scale *= .725;
			spatial.x = 10;
			spatial.y = super.shellApi.viewportHeight - 10;
			DisplayUtils.moveToBack( display.displayObject );
			
			entity = EntityUtils.createSpatialEntity( this, asset.thermostat.bar );
			spatial = entity.get( Spatial );
			
			shakeMotion = new ShakeMotion( new RectangleZone( -1, -1, 1, 1 ));
			shakeMotion.active = false;
			thermostat.add( new SpatialAddition()).add( shakeMotion ).add( tween );
			
			gauge.maskSpatial = spatial;
			gauge.shakeMotion = shakeMotion;
			gauge.blueLiquidDisplayObject = asset.thermostat.blueLiquid;
			gauge.blueOrbDisplayObject = asset.thermostat.blueOrb;
			gauge.redLiquidDisplayObject = asset.thermostat.redLiquid;
			gauge.redOrbDisplayObject = asset.thermostat.redOrb;
			gauge.thermostat = display;
			
			gauge.active = false;
			gauge.freezingWater = true;
			gauge.coldTimer = gauge.heatTimer = 2;
			gauge.thermostatTween = tween;
			gauge.step = 2;
			gauge.alertTemp = 50;
			
			if ( !DataUtils.isNull( currentTemperature ))
			{
				if( currentTemperature == 0 || !shellApi.checkEvent( _events.PLAYED_INTRO ))
				{
					currentTemperature = 100;
				}
				
				gauge.temperature = currentTemperature;
			}
				
			else
			{
				gauge.temperature = 100;
				gauge.maskSpatial.scaleY = 1;
				
				shellApi.setUserField( (super.events as Survival2Events).TEMPERATURE_FIELD, gauge.temperature, shellApi.island  );
			}
			
			player.add( gauge );
			
			display.container.setChildIndex( display.displayObject, 0 );
			
			system = new ThermostatSystem(); 
			system.frozen.addOnce( freeze );
			
			addSystem( system, SystemPriorities.moveComplete );
			addSystem( new ShakeMotionSystem(), SystemPriorities.move );
		}
		
		private function freeze():void
		{
			var introPopup:DialogPicturePopup = new DialogPicturePopup(overlayContainer);
			introPopup.updateText("you fell into freezing water!", "try again");
			introPopup.configData("freezePopup.swf", "scenes/survival2/shared/freezePopup/");
			introPopup.removed.addOnce(reloadScene);
			addChildGroup(introPopup);
		}
		
		private function reloadScene(group:Group):void
		{
			removeSystemByClass(ThermostatSystem);
			switch( shellApi.sceneName )
			{
				case "FishingHole":
					shellApi.loadScene( FishingHole);
					break;
				
				case "Trees":
					shellApi.loadScene( Trees );
					break;
				
				case "UnfrozenLake":
					shellApi.loadScene( UnfrozenLake, 3646, 1410 );
					break;
				
				case "BeaverDen":
					shellApi.loadScene( BeaverDen );
					break;
			}
		}
	}
}