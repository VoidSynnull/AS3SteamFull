package game.scenes.carnival.midwayDay{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.ui.ButtonCreator;
	import game.data.sound.SoundModifier;
	import game.data.ui.ToolTipType;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.carnival.CarnivalEvents;
	import game.scenes.carnival.ridesDay.DayToDusk;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.actions.GetItemAction;
	import game.systems.actionChain.actions.MoveAction;
	import game.systems.actionChain.actions.PanAction;
	import game.systems.actionChain.actions.RemoveItemAction;
	import game.systems.actionChain.actions.TalkAction;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	public class MidwayDay extends PlatformerGameScene
	{
		private var _events:CarnivalEvents;
		private var _foodworker:Entity;
		private var _duckworker:Entity;
		private var _edgar:Entity;
		private var _spigotflow_mc:Entity;
		private var _hose_mc:MovieClip;
		private var _garbage_mc:Entity;
		private var _pool_mc:Entity;
		private var _audio:Audio;
		private var timeline:Timeline;
		private var _soundEntity:Entity;
		private var foodieInteraction:SceneInteraction;
		private var _waterSoundEntity:Entity;
		private var _waterAudio:Audio;
		private var _poolSoundEntity:Entity;
		private var _poolAudio:Audio;

		private var gCampaignName:String = "MonsterCarnival";

		public function MidwayDay()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/carnival/midwayDay/";
			
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
			
			super.shellApi.eventTriggered.add(handleEventTriggered);	
			
			_edgar = super.getEntityById("edgar");
			
			_foodworker = super.getEntityById("foodstandWorker");
			
			var foodieInteraction:SceneInteraction = _foodworker.get(SceneInteraction);
			foodieInteraction.reached.removeAll();
			foodieInteraction.reached.add(foodieClicked);
			
			_duckworker = super.getEntityById("duckGameWorker");
			
			var duckInteraction:SceneInteraction = _duckworker.get(SceneInteraction);
			duckInteraction.reached.removeAll();
			duckInteraction.reached.add(duckieClicked);
			
			ButtonCreator.createButtonEntity( MovieClip(super._hitContainer).garbage_btn, this, handleGarbageButtonClicked, null, null, ToolTipType.CLICK);
			
			_soundEntity = AudioUtils.createSoundEntity("_soundEntity");	
			_audio = new Audio();
			_soundEntity.add(_audio);
			_soundEntity.add(new Spatial(1073, 1947));
			_soundEntity.add(new AudioRange(600, 0, 1, Quad.easeIn));
			_soundEntity.add(new Id("soundSource"));
			super.addEntity(_soundEntity);
			
			_spigotflow_mc = EntityUtils.createSpatialEntity( this, MovieClip( MovieClip(super._hitContainer).spigotflow_mc ) );
			TimelineUtils.convertClip( MovieClip( MovieClip(super._hitContainer).spigotflow_mc ), this, _spigotflow_mc, null, false );
			Timeline(_spigotflow_mc.get(Timeline)).gotoAndStop(1);
			
			_garbage_mc = EntityUtils.createSpatialEntity( this, MovieClip( MovieClip(super._hitContainer).garbage_mc ) );
			TimelineUtils.convertClip( MovieClip( MovieClip(super._hitContainer).garbage_mc ), this, _garbage_mc, null, false );
			Timeline(_garbage_mc.get(Timeline)).gotoAndStop(1);		
			
			_pool_mc = EntityUtils.createSpatialEntity( this, MovieClip( MovieClip(super._hitContainer).pool_mc ) );
			TimelineUtils.convertClip( MovieClip( MovieClip(super._hitContainer).pool_mc ), this, _pool_mc, null, false );
			Timeline(_pool_mc.get(Timeline)).gotoAndStop(1);	
			
			_hose_mc  = MovieClip(super._hitContainer).hose_mc;			
			if (!this.shellApi.checkEvent(_events.WATER_FIXED)){
				ButtonCreator.createButtonEntity( MovieClip(super._hitContainer).spigot_btn, this, handleWaterButtonClicked, null, null, ToolTipType.CLICK);
				_hose_mc.visible = false;
			}else{
				_hose_mc.visible = true;
				Timeline(_pool_mc.get(Timeline)).gotoAndStop("end");
			}
			
			_waterSoundEntity = AudioUtils.createSoundEntity("_waterSoundEntity");	
			_waterAudio = new Audio();
			_waterSoundEntity.add(_waterAudio);			
			super.addEntity(_waterSoundEntity);			
			
			_poolSoundEntity = AudioUtils.createSoundEntity("_poolSoundEntity");	
			_poolAudio = new Audio();
			_poolSoundEntity.add(_poolAudio);			
			super.addEntity(_poolSoundEntity);

			/**
			 * player might have just come back from fixing the lever in the ferris scene. Attempt to start the carnival.
			 */
			this.checkStartCarnival();

		}	
		
		private function handleEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			switch(event){
				case "giveSugar":
					_foodworker.get(Interaction).click.dispatch( _foodworker );
					//player.get(Spatial).y = 1945;
					//CharUtils.moveToTarget(player, 1330, 1945, false, giveFoodieSugar);	
					lockControl();
					break;
				case "useHose":					
					hookUpHose();
					break;
				case "ducksSwimming":

					super.shellApi.camera.target = super.player.get(Spatial);
					restoreControl();

					this.checkStartCarnival();

				break;
			}
			
		}

		/**
		 * Check to see if the carnival should begin.
		 */
		private function checkStartCarnival():void {

			if ( !super.shellApi.checkEvent( this._events.SET_DAY ) || !super.shellApi.checkEvent( this._events.REPLACED_LEVER ) ||
				!super.shellApi.checkEvent( this._events.WATER_FIXED ) || !super.shellApi.checkEvent( this._events.SUGAR_GIVEN ) ) {
				return;
			}

			/**
			 * Have edgar run into the scene and blah blah blah.
			 */

			(this._edgar.get( Display ) as Display ).visible = true;
			( this._edgar.get( Sleep ) as Sleep ).sleeping = false;

			var sp:Spatial = this.player.get( Spatial );
			var p:Point;
			if ( (this._edgar.get(Spatial) as Spatial).x > sp.x ) {
				p = new Point( sp.x + 100, sp.y );
			} else {
				p = new Point( sp.x - 100, sp.y );
			} // end-if.

			var actChain:ActionChain = new ActionChain( this );
			actChain.lockInput = true;

			actChain.addAction( new MoveAction( this._edgar, p, null, sp.x ) );
			actChain.addAction( new TalkAction( this._edgar, "startCarnival" ) );

			actChain.execute( this.startCarnival );

		} //

		private function startCarnival( ac:ActionChain ):void 
		{
			shellApi.takePhotoByEvent( _events.SET_EVENING, bringOnTheNight );
		}

		private function bringOnTheNight():void
		{
			//cutscene popup
			var popup2:DayToDusk = super.addChildGroup( new DayToDusk( super.overlayContainer )) as DayToDusk;
			popup2.id = "dayToDusk";

		} //

		private function hookUpHose( ...args ):void 
		{				
			CharUtils.moveToTarget(player, 1030, 1947, false, connectHose);	
		}
		
		private function connectHose( ...args ):void 
		{
			lockControl();
			super.shellApi.camera.target = _duckworker.get(Spatial);
			Timeline(_spigotflow_mc.get(Timeline)).gotoAndStop(1);	
			_audio.stop(SoundManager.EFFECTS_PATH + "water_fountain_01_loop.mp3");		
			_poolAudio.play(SoundManager.EFFECTS_PATH + "bathtub_fill_01_loop.mp3", true);		
			
			_hose_mc.visible = true;
			Timeline(_pool_mc.get(Timeline)).gotoAndPlay(2);	
			_pool_mc.get(Timeline).handleLabel( "end", finishFill, false );

		} 
		
		private function finishFill(...args):void	
		{
			Timeline(_pool_mc.get(Timeline)).gotoAndStop("end");
			super.shellApi.triggerEvent(_events.WATER_FIXED, true);
			super.shellApi.removeItem(_events.HOSE);
			var dialog:Dialog = _duckworker.get(Dialog);
			dialog.sayById("ducksSwim");
			dialog.complete.addOnce(restoreControl);
			_poolAudio.stop(SoundManager.EFFECTS_PATH + "bathtub_fill_01_loop.mp3");
		}
		
		private function loopWater(...args):void	
		{
			Timeline(_spigotflow_mc.get(Timeline)).gotoAndPlay("loop");
		}
		
		private function handleWaterButtonClicked(entity:Entity):void	
		{
			if (_hose_mc.visible == false){
				super.shellApi.triggerEvent("faucet");// trigger audio sound
				_spigotflow_mc.get(Timeline).handleLabel( "doLoop", loopWater, false );
				Timeline(_spigotflow_mc.get(Timeline)).gotoAndPlay(2)			
				_audio.play(SoundManager.EFFECTS_PATH + "water_fountain_01_loop.mp3", true, [SoundModifier.POSITION, SoundModifier.EFFECTS]);	
				Dialog(player.get(Dialog)).sayById("waterSpigot");
			}
		}
		
		private function stopCat(...args):void	
		{
			Timeline(_garbage_mc.get(Timeline)).gotoAndStop(1);
		}
		
		private function handleGarbageButtonClicked(entity:Entity):void	
		{
			super.shellApi.triggerEvent("cat");
			Timeline(_garbage_mc.get(Timeline)).gotoAndPlay(2)	
			_garbage_mc.get(Timeline).handleLabel( "end", stopCat );
		}
		
		private function foodieClicked(player:Entity, npc:Entity):void
		{
			if (!this.shellApi.checkEvent(_events.ASKED_SUGAR)){
				problemWithSugar();
				lockControl();
			}else if(super.shellApi.checkHasItem(_events.SUGAR)){
				giveFoodieSugar();
			}else if (!this.shellApi.checkEvent(_events.SUGAR_GIVEN) && this.shellApi.checkEvent(_events.ASKED_SUGAR)){
				Dialog(_foodworker.get(Dialog)).sayById("findSugar");
			}else if(this.shellApi.checkEvent(_events.SUGAR_GIVEN)){
				Dialog(_foodworker.get(Dialog)).sayById("thanksSugarHelp");
			}
		}
		
		private function duckieClicked(player:Entity, npc:Entity):void{
			if (!this.shellApi.checkEvent(_events.ASKED_WATER)){
				problemWithDucks();	
				lockControl();
			}else if (this.shellApi.checkEvent(_events.ASKED_WATER) && !this.shellApi.checkEvent(_events.WATER_FIXED)){
				Dialog(_duckworker.get(Dialog)).sayById("needDuckHelp");
			}else if(this.shellApi.checkEvent(_events.WATER_FIXED)){
				Dialog(_duckworker.get(Dialog)).sayById("ducksSwim");
			}
		}				
		
		private function problemWithSugar():void 
		{			
			var actChain:ActionChain = new ActionChain( this );
			actChain.lockInput = true;			
			
			actChain.addAction( new TalkAction( _foodworker, "outSugar" ) );
			actChain.addAction( new TalkAction( player, "askSugarHelp" ) );
			actChain.addAction( new TalkAction( _foodworker, "needSugarHelp" ) );	
			actChain.addAction( new GetItemAction( _events.SUGAR_FORMULA, true ) );
			
			actChain.execute(this.askedSugarHelp);			
			lockControl();
		} 
		
		private function askedSugarHelp( ...args ):void 
		{	
			super.shellApi.triggerEvent(_events.ASKED_SUGAR, true)
			restoreControl();			
		} 
		
		private function problemWithDucks():void 
		{			
			var actChain:ActionChain = new ActionChain( this );
			actChain.lockInput = true;			
			
			actChain.addAction( new TalkAction( _duckworker, "duckDisaster" ) );
			actChain.addAction( new TalkAction( player, "askDuckHelp" ) );
			actChain.addAction( new TalkAction( _duckworker, "needDuckHelp" ) );		
			
			actChain.execute(this.askedDuckHelp);			
			lockControl();
		} 
		
		private function askedDuckHelp( ...args ):void 
		{						
			super.shellApi.triggerEvent(_events.ASKED_WATER, true)
			super.shellApi.triggerEvent(_events.TALKED_TO_DUCK_GAME_WORKER, true)
			restoreControl();			
		} 
		
		private function giveFoodieSugar(...args):void {
			
			if (player.get(Spatial).x > _foodworker.get(Spatial).x){
				CharUtils.setDirection(player, false);
			}else{
				CharUtils.setDirection(player, true);
			}

			var actChain:ActionChain = new ActionChain( this );
			actChain.lockInput = true;	
			var playerSpatial:Spatial = this.player.get(Spatial);
			var foodSpatial:Spatial = this._foodworker.get(Spatial);
			
			actChain.addAction( new RemoveItemAction( this._events.SUGAR, "foodstandWorker" ) );
			actChain.addAction( new TalkAction( this._foodworker, "giveSugar" ) );
			actChain.addAction( new GetItemAction( this._events.FRIED_DOUGH, true ) );
			var egdarXPosition:int = ( playerSpatial.x > foodSpatial.x ) ? playerSpatial.x + 100 : playerSpatial.x - 100;	// position edgar relative to player
			actChain.addAction( new MoveAction( this._edgar, new Point( egdarXPosition, 1945 ) ) );
			actChain.addAction( new PanAction( this._edgar ) );
			actChain.addAction( new TalkAction( this._edgar, "friedDoughReady" ) );
			actChain.addAction( new TalkAction( this._foodworker, "backToWork" ) );

			actChain.addAction( new PanAction( this.player ) );
			
			if ( !this.shellApi.checkEvent( this._events.REPLACED_LEVER ) ||
				!this.shellApi.checkEvent( this._events.WATER_FIXED ) ) {
				actChain.addAction( new MoveAction( this._edgar, new Point( 2500, 1945 ) ) );
			}else{
				actChain.addAction( new TalkAction( this._edgar, "startCarnival" ) );
			}
			
			actChain.execute(this.gaveBackSugar);			
			lockControl();
		} 
		
		private function gaveBackSugar( ...args ):void 
		{

			/**
			 * We can't remove edgar as was done previously because he might run back into the scene
			 * to tell the player the carnival is starting.
			 */
			if (_edgar.get(Spatial).x > 2200){
				//super.removeEntity( _edgar );
				(this._edgar.get( Display ) as Display ).visible = false;
				( this._edgar.get( Sleep ) as Sleep ).sleeping = true;
			}

			super.shellApi.removeItem(_events.SUGAR);
			super.shellApi.triggerEvent( _events.SUGAR_GIVEN, true );
			restoreControl();

			if ( this.shellApi.checkEvent( this._events.REPLACED_LEVER ) &&
				this.shellApi.checkEvent( this._events.WATER_FIXED ) && this.shellApi.checkEvent( this._events.SUGAR_GIVEN ) ) {
				startCarnival(null);
			}
			

		} 

		private function lockControl():void
		{
			MotionUtils.zeroMotion(super.player, "x");
			CharUtils.lockControls(super.player, true, true);
			SceneUtil.lockInput(this, true);
		}
		
		private function restoreControl(...args):void
		{
			CharUtils.lockControls(super.player, false, false);
			MotionUtils.zeroMotion(super.player);
			SceneUtil.lockInput(this, false);
		}
		
	}
}







