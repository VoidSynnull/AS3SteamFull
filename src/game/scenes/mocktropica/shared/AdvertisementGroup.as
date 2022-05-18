package game.scenes.mocktropica.shared
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.group.DisplayGroup;
	import engine.util.Command;
	
	import game.components.particles.Flame;
	import game.data.TimedEvent;
	import game.scene.template.CollisionGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.mocktropica.MocktropicaEvents;
	import game.scenes.mocktropica.shared.components.AdvertisementComponent;
	import game.scenes.mocktropica.shared.components.CreateRandomAdComponent;
	import game.scenes.mocktropica.shared.popups.MocktropicaAdvertisementPopup;
	import game.scenes.mocktropica.shared.systems.AdvertisementSystem;
	import game.scenes.mocktropica.shared.systems.CreateRandomAdSystem;
	import game.systems.SystemPriorities;
	import game.systems.particles.FlameSystem;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	
	import org.osflash.signals.Signal;
	
	public class AdvertisementGroup extends DisplayGroup
	{
		public function AdvertisementGroup( scene:PlatformerGameScene, container:DisplayObjectContainer=null )
		{
			super( container );
			this.id = "mocktropicaAdvertisementGroup";
			
			_scene = scene;
			_complete = new Signal();
		}
		
		override public function init( container:DisplayObjectContainer=null ):void 
		{
			super.init( container );
			
			_events = super.shellApi.islandEvents as MocktropicaEvents;
			var popup:MocktropicaAdvertisementPopup;
			
			if( !super.shellApi.checkEvent( _events.BOUGHT_ADS ))
			{
				var collisionGroup:CollisionGroup = super.getGroupById( "collisionGroup" ) as CollisionGroup;
				var advertisementSystem:AdvertisementSystem = new AdvertisementSystem( collisionGroup.hitBitmapData, collisionGroup.hitBitmapDataScale, collisionGroup.hitBitmapOffsetX, collisionGroup.hitBitmapOffsetY );
				advertisementSystem.removeAd.add( removeAd );
				
				_scene.addSystem( advertisementSystem, SystemPriorities.move );
				
				if( super.shellApi.checkEvent( _events.NEW_AD_UNIT ))
				{
					randomAd = new CreateRandomAdComponent();
					randomAd.adSystem = this;
					
					super.shellApi.player.add( randomAd );
					super.addSystem( new CreateRandomAdSystem(), SystemPriorities.update );
				}
				
				if( super.shellApi.checkEvent( _events.SPOKE_SALES_MANAGER_AD ))
				{
					popup = new MocktropicaAdvertisementPopup( 3, _scene.hitContainer );
					_scene.addChildGroup( popup );
				}
			}
		} 

		// create a boss advertisement or a random
		public function createAdvertisement( id:String, callback:Function=null ):void
		{
			var container:DisplayObjectContainer;
			var popup:MocktropicaAdvertisementPopup;

			var level:uint = 0;

			switch( id )
			{
				case _events.ADVERTISEMENT_BOSS_1:
					container = _scene.overlayContainer;
					level = 1;
					break;
				case _events.ADVERTISEMENT_BOSS_2:
					container = _scene.overlayContainer;
					level = 2;
					break;
				case _events.ADVERTISEMENT_BOSS_3:
					container = _scene.hitContainer;
					level = 3;
					break;
			}
			
			popup = new MocktropicaAdvertisementPopup( level, container );
	
			if( callback && level > 0 )
			{
				_complete.add( callback );
			}
			_scene.addChildGroup( popup );
		}
		
		public function createRandomAds():void
		{
			if( randomAd.count < randomAd.max )
			{
				var popup:MocktropicaAdvertisementPopup;
				popup = new MocktropicaAdvertisementPopup( 0, _scene.hitContainer );
				_scene.addChildGroup( popup );
				
				randomAd.count ++;
			}
		}
		
		private function removeAd( adEnt:Entity ):void
		{
			var ad:AdvertisementComponent = adEnt.get( AdvertisementComponent );
			var entity:Entity;
			var tween:Tween;
			var display:Display = ad.visual.get( Display );
			var spatial:Spatial = ad.visual.get( Spatial );
			
			if( ad.level > 0 )
			{
				if( ad.level == 2 )
				{
					shellApi.triggerEvent( _events.START_POPUP_BURN, true );
					ad.flame.alpha = 1;
					var flames:Array = [ ad.flame[ "flame1" ], ad.flame[ "flame2" ]];
						
					for(var i:int = 0; i < flames.length; i++)
					{
						entity = new Entity();
						
						if( i == 0 )
						{
							
							entity = EntityUtils.createSpatialEntity( this, ad.flame );
							EntityUtils.getDisplay( entity ).alpha = .65;
							entity.add( new Id( "flame" ));
							entity.add( new Flame( flames[ i ], true ));
						}
						else
						{
							entity.add( new Flame( flames[ i ], false ));
							this.addEntity( entity );
						}
					}
					
					this.addSystem( new FlameSystem(), SystemPriorities.lowest );
					
					tween = ad.visual.get( Tween );
					tween.to( display, 1, { alpha : 0 }, "alpha" );
					tween.to( spatial, .5, { scale : .25, onComplete : setBurn, onCompleteParams : [ adEnt ]}, "scale" );
					
					spatial = adEnt.get( Spatial );
					spatial.rotation = 0;
				}
					
				else
				{
					tween = ad.visual.get( Tween );
					
					tween.to( display, 1, { alpha : 0 }, "alpha" );
					tween.to( spatial, 1, { scale : .25, onComplete : close, onCompleteParams : [ adEnt ]}, "scale" );
				}
			}
			else
			{
				tween = ad.visual.get( Tween );
				
				tween.to( display, 1, { alpha : 0 }, "alpha" );
				tween.to( spatial, 1, { scale : .25, onComplete : normalClose, onCompleteParams : [ adEnt ]}, "scale" );
				randomAd.count --;
			}
		}
		
		private function setBurn( adEnt:Entity ):void
		{
			var entity:Entity = super.getEntityById( "flame" );
			var spatial:Spatial = entity.get( Spatial );
			var tween:Tween = new Tween();
			
			// scale flames as destroying ad
			spatial.rotation = 0;
			tween.to( spatial, .5, { scale : .1 });
			entity.add( tween );
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, Command.create( close, adEnt )));
		}
		
		private function close( adEnt:Entity ):void
		{
			var ad:AdvertisementComponent = adEnt.get( AdvertisementComponent );
			ad.popup.close();
			_complete.dispatch();
		}
		
		private function normalClose( adEnt:Entity ):void
		{
			var ad:AdvertisementComponent = adEnt.get( AdvertisementComponent );
			ad.popup.close();
		}
		
		public var _complete:Signal;
		public var randomAd:CreateRandomAdComponent;
		private var _events:MocktropicaEvents;
		private var _scene:PlatformerGameScene;
	}
}