package game.scenes.ghd.prehistoric2
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.components.entity.Dialog;
	import game.components.entity.character.Character;
	import game.components.hit.CurrentHit;
	import game.components.hit.Hazard;
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.data.animation.entity.character.Celebrate;
	import game.data.scene.characterDialog.DialogData;
	import game.scene.template.AudioGroup;
	import game.scenes.ghd.GalacticHotDogScene;
	import game.scenes.ghd.shared.PrehistoricGroup;
	import game.ui.showItem.ShowItem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	public class Prehistoric2 extends GalacticHotDogScene
	{
		private const DACTYL:String 		=		"dactyl";
		private const TRIGGER:String		=		"trigger";
		private const BUSH_RUSTLE:String	=		"bush_rustle_01.mp3";
		private var _cosmoe:Entity;
		private var _swat:Hazard;
		private var _wingHit:Entity;
		private var _audioGroup:AudioGroup;
		
		public function Prehistoric2()
		{
			super();
		}
		
		override public function init( container:DisplayObjectContainer = null ):void
		{			
			super.groupPrefix = "scenes/ghd/prehistoric2/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			this.shellApi.setUserField(_events.PLANET_FIELD, _events.PREHISTORIC, this.shellApi.island, true);
			
			
			_cosmoe = getEntityById( "cosmoe" );
			
			_wingHit = getEntityById( "wingSpan" );
			_swat = _wingHit.get( Hazard );
			_wingHit.remove( Hazard );
			
			if( !shellApi.checkEvent( _events.RECOVERED_COSMOE ) && shellApi.checkEvent( _events.WORM_HOLE_APPEARED ))
			{
				var display:Display = _cosmoe.get( Display );
				
				display.setContainer( _hitContainer[ "cosmoeContainer" ]);
				ToolTipCreator.removeFromEntity( _cosmoe );
				_hitContainer[ "egg" ].alpha = 0;
				
				var goober:Entity = SkinUtils.getSkinPartEntity( _cosmoe, SkinUtils.ITEM );
				display = goober.get( Display );
				display.moveToFront();
			}
			else
			{
				_hitContainer.removeChild( _hitContainer[ "crackedEgg" ]);
			}
			
			var prehistoricGroup:PrehistoricGroup = this.addChildGroup( new PrehistoricGroup()) as PrehistoricGroup;
			prehistoricGroup.createDactyls( this, _hitContainer, approachNest );
		}
		
		override protected function eventTriggers( event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			if( player )
			{
				var currentHitId:Id = CurrentHit( player.get( CurrentHit )).hit.get( Id );
				if( event == _events.USE_EGG && shellApi.checkHasItem( _events.EGG ))
				{
					if( currentHitId.id == "nest" )
					{
						var clickHit:Entity = getEntityById( "actionClip" );
						var spatial:Spatial = clickHit.get( Spatial );
						
						SceneUtil.lockInput( this );
						CharUtils.moveToTarget( player, spatial.x, spatial.y, true, placeEgg );
					}
					else
					{
						var dialog:Dialog = player.get( Dialog );
						dialog.sayById( "not_here" );
					}
				}
			}
			super.eventTriggers( event, save, init, removeEvent );
		}
		
		/** COSMOE IN NEST FUNCTIONS **/		
		private function approachNest( player:Entity, click:Entity ):void
		{
			var dactyl:Entity = getEntityById( "baby" );
			var timeline:Timeline = dactyl.get( Timeline );
			var audio:Audio = dactyl.get( Audio );
			audio.playCurrentAction( TRIGGER );
			
			timeline.gotoAndPlay( "cry" );
			timeline.handleLabel( "loop", momaSwat );
		}
		
		private function momaSwat():void
		{
			var dactyl:Entity = getEntityById( "moma" );
			var timeline:Timeline = dactyl.get( Timeline );
			
			timeline.gotoAndPlay( "turn" );
			timeline.handleLabel( "slap", addHazard );
			timeline.handleLabel( "turnBack", resetNestDactyls );
		}
		
		private function addHazard():void
		{
			_wingHit.add( _swat );
		}
		
		private function resetNestDactyls():void
		{
			var dactyl:Entity = getEntityById( "baby" );
			var timeline:Timeline = dactyl.get( Timeline );
			timeline.gotoAndPlay( "idle" );
			
			var audio:Audio = dactyl.get( Audio );
			audio.stopAll();
			
			_wingHit.remove( Hazard );
			
			if( !shellApi.checkEvent( _events.RECOVERED_COSMOE ))
			{
				var dialog:Dialog = _cosmoe.get( Dialog );
				dialog.sayById( "baby" );
			}
		}
		
		private function placeEgg( player:Entity ):void
		{
			var showItem:ShowItem = super.getGroupById( ShowItem.GROUP_ID ) as ShowItem;
			var clipHit:Entity = getEntityById( "actionClip" );
			
			if( !showItem )
			{
				showItem = new ShowItem();
				addChildGroup( showItem );
			}
			
			showItem.takeItem( _events.EGG, "ghd", clipHit );
			showItem.transitionComplete.addOnce( releaseCosmoe );
		}
		
		private function releaseCosmoe():void
		{
			_hitContainer.removeChild( _hitContainer[ "crackedEgg" ]);
			_hitContainer[ "egg" ].alpha = 1;
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + BUSH_RUSTLE );
			
			shellApi.removeItem( _events.EGG );
			var display:Display = _cosmoe.get( Display );
			var spatial:Spatial = player.get( Spatial );
			
			display.setContainer( _hitContainer );
			CharUtils.moveToTarget( _cosmoe, spatial.x + 100, spatial.y, true, savedMyButt );
			CharUtils.setDirection( player, true );
		}
		
		private function savedMyButt( cosmoe:Entity ):void
		{
			CharUtils.setAnim( _cosmoe, Celebrate );
			var timeline:Timeline = _cosmoe.get( Timeline );
			timeline.handleLabel( "ending", backToTheShip );
		}
		
		private function backToTheShip():void
		{
			var dialog:Dialog = _cosmoe.get( Dialog );
			dialog.sayById( "free" );
			dialog.complete.addOnce( exitCosmoe );
		}
		
		private function exitCosmoe( dialogData:DialogData ):void
		{
			CharUtils.moveToTarget( _cosmoe, 1900, 1880, true, removeCosmoe );
		}
		
		private function removeCosmoe( ...args ):void
		{
			SceneUtil.lockInput( this, false, false );
			shellApi.completeEvent( _events.RECOVERED_COSMOE );
			
			removeEntity( _cosmoe );
		}
	}
}