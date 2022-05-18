package game.scenes.survival1.morningAfter
{
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Sleep;
	import game.data.comm.PopResponse;
	import game.scene.template.CutScene;
	import game.scenes.survival1.Survival1Events;
	import game.scenes.survival1.shared.popups.VictoryPopup;
	import game.scenes.time.shared.emitters.Fire;
	import game.scenes.time.shared.emitters.FireSmoke;
	import game.ui.popup.IslandEndingPopup;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TweenUtils;
	
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class MorningAfter extends CutScene
	{
		private var _loop:int = 0;
		private var _binoculars:Entity;
		private var _horizontalBar:Entity;
		private var _verticalBar:Entity;
		
		public function MorningAfter()
		{
			super();
			configData("scenes/survival1/morningAfter/", Survival1Events(events).CRASH_LANDING);
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			_binoculars = EntityUtils.createSpatialEntity( this, screen.binoculars );

			_horizontalBar = EntityUtils.createSpatialEntity( this, screen.binoculars.hbar );
			
			_verticalBar = EntityUtils.createSpatialEntity( this, screen.binoculars.vbar );
			
			var name:String = "fireInteraction";
			var fire:Fire = new Fire();
			fire.init( 2, new RectangleZone( -13, -4, 13, -4 ));
			EmitterCreator.create(this, screen[ "campFire" ], fire );
			var smoke:FireSmoke = new FireSmoke();
			smoke.init( 9, new LineZone( new Point( -2, -20 ), new Point( 2, -40 )), new RectangleZone( -10, -50, 10, -5 ));
			EmitterCreator.create(this, screen[ "campFire" ], smoke );			
			var fireEnt:Entity = getEntityById(name);
		}
		
		override public function setUpCharacters():void
		{
			setEntityContainer(player, screen.player_container);
			
			CharUtils.setAnimSequence(player, new <Class>[Sleep], true);
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 3, 1, launchVictory ));
			
			// remove player's motion from the final cutscene
			player.remove( Motion );
			start();
		}
		
		private function launchVictory():void
		{
			Display(getEntityById( "input" ).get( Display )).visible = false;
			
			var spatial:Spatial = _binoculars.get(Spatial);
			TweenUtils.entityTo(_binoculars, Spatial, 3, { x : spatial.x - 100, y : spatial.y - 50, onComplete : zoomIn });
		}
		
		private function zoomIn():void
		{	
			var spatial:Spatial = sceneEntity.get(Spatial);
			TweenUtils.entityTo(sceneEntity, Spatial, 5, { x : - 500, y : - 600, scaleX : spatial.scaleX * 2, scaleY : spatial.scaleY * 2 });
			
			spatial = _binoculars.get(Spatial);
			TweenUtils.entityTo(_binoculars, Spatial, 7, { x : spatial.x - 20, y : spatial.y + 250, scaleX : .5, scaleY : .5 });
			
			spatial = _horizontalBar.get(Spatial);
			TweenUtils.entityTo(_horizontalBar, Spatial, 7, { x : spatial.x - 150 });
			
			spatial = _verticalBar.get( Spatial );
			TweenUtils.entityTo(_verticalBar, Spatial, 7, { y : spatial.y - 450 });
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 8, 1, fadeToBlack ));
		}
		
		private function fadeToBlack():void
		{
			shellApi.completedIsland('', onCompletions);
		}

		private function onCompletions(response:PopResponse):void
		{
			SceneUtil.lockInput( this, false );
			this.addChildGroup(new IslandEndingPopup(this.overlayContainer));
			//super.addChildGroup( new VictoryPopup( super.overlayContainer ));
			end();
		}
	}
}