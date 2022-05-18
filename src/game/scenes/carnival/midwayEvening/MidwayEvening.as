package game.scenes.carnival.midwayEvening{
	import com.greensock.easing.Linear;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	
	import game.components.motion.Edge;
	import game.components.entity.Dialog;
	import game.components.scene.SceneInteraction;
	import game.components.hit.Platform;
	import game.components.hit.Wall;
	import game.creators.ui.ButtonCreator;
	import game.scenes.carnival.CarnivalEvents;
	import game.data.ui.ToolTipType;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.carnival.balloonPop.BalloonPop;
	import game.scenes.carnival.shared.popups.duckGame.DuckGamePopup;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.actions.GetItemAction;
	import game.systems.actionChain.actions.MoveAction;
	import game.systems.actionChain.actions.RemoveItemAction;
	import game.systems.actionChain.actions.TalkAction;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.TweenUtils;
	
	public class MidwayEvening extends PlatformerGameScene
	{
		private var _events:CarnivalEvents;
		private var _foodworker:Entity;
		private var _bubby:Entity;
		private var _guesser:Entity;
		private var _woman:Entity;
		private var _duckWorker:Entity;
		private var _needle:Entity;
		private var _edgar:Entity;
		private var _scalemc:Entity;
		
		public function MidwayEvening()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/carnival/midwayEvening/";
			//super.showHits = true;
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

			_scalemc = EntityUtils.createSpatialEntity( this, MovieClip( MovieClip(super._hitContainer).dynamicHit ) );
			
			_woman = super.getEntityById("woman");			
			_edgar = super.getEntityById("edgar");
			var edgarInteraction:SceneInteraction = _edgar.get(SceneInteraction);
			edgarInteraction.reached.removeAll();
			edgarInteraction.reached.add(edgarClicked);
			
			_bubby = super.getEntityById("bubby");
			var bubbyInteraction:SceneInteraction = _bubby.get(SceneInteraction);
			bubbyInteraction.reached.removeAll();
			bubbyInteraction.reached.add(bubbyClicked);
			
			_duckWorker = super.getEntityById("duckGameWorker");	
			
			_foodworker = super.getEntityById("foodstandWorker");			
			var foodieInteraction:SceneInteraction = _foodworker.get(SceneInteraction);
			foodieInteraction.reached.removeAll();
			foodieInteraction.reached.add(foodieClicked);			
			
			_guesser = super.getEntityById("guesser");			
			var guesserInteraction:SceneInteraction = _guesser.get(SceneInteraction);
			guesserInteraction.reached.removeAll();
			guesserInteraction.reached.add(guesserClicked);
			
			
			if (super.shellApi.checkHasItem(_events.SHARPENED_DART)|| super.shellApi.checkHasItem(_events.BLUNTED_DART)){
				ButtonCreator.createButtonEntity( MovieClip(super._hitContainer).dart_btn, this, handleDartButtonClicked, null, null, ToolTipType.CLICK);
			}
			
			ButtonCreator.createButtonEntity( MovieClip(super._hitContainer).pool_btn, this, handlePoolButtonClicked, null, null, ToolTipType.CLICK);
			
			_needle = EntityUtils.createSpatialEntity(this, MovieClip(super._hitContainer).needle_mc);
			
			if (this.shellApi.checkEvent(_events.WON_BALLOON_POP) && super.shellApi.sceneManager.previousScene == "game.scenes.carnival.balloonPop::BalloonPop"){				
				if (!this.shellApi.checkEvent(_events.GOT_FRY_OIL) && !super.shellApi.checkHasItem(_events.SOUVENIR_CUP)){
					wonDartGame();
				}else{
					Dialog(_edgar.get(Dialog)).sayById("wonBallon");	
				}
			}	
			
			if (this.shellApi.checkEvent(_events.TEENS_FRIGHTENED)){
				super.removeEntity(_duckWorker);
				super.removeEntity(_foodworker);
				super.removeEntity(_guesser);
			}			
			
		}			
		
		private function handleEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			switch(event){
				case "getOnScale":					
					startWeightGuess();
					break;
				case "giveBluntedDart":	
					giveBluntedDart();
					break;
				case "giveCup":		
					if(!super.shellApi.checkEvent(_events.SPOKE_ABOUT_GREASE)){
						Dialog(player.get(Dialog)).sayById("notThirsty");
					}else{
						_foodworker.get(Interaction).click.dispatch( _foodworker );
					}
					break;
				case "useDart":					
					startDartGame();
					break;
			}
			
		}	
		
		private function edgarClicked(...args):void{
			if (this.shellApi.checkEvent(_events.WON_BALLOON_POP)){
				Dialog(_edgar.get(Dialog)).sayById("wonBallon");	
			}else{						
				Dialog(_edgar.get(Dialog)).sayById("noPopping");				
			}
		}
		
		private function bubbyClicked(...args):void{
			if (!this.shellApi.checkEvent(_events.GOT_BLUNTED_DART)){
				Dialog(_bubby.get(Dialog)).sayById("bluntDart");	
			}else{						
				Dialog(_bubby.get(Dialog)).sayById("ballonsWontPop");				
			}
		}		
		
		private function giveBluntedDart():void 
		{			
			var actChain:ActionChain = new ActionChain( this );
			actChain.lockInput = true;			
			
			actChain.addAction( new GetItemAction( _events.BLUNTED_DART, true ) );
			actChain.addAction( new TalkAction( player, "gotBluntedDart" ) );
			
			actChain.execute(this.gotBluntedDart);			
			lockControl();
		} 
		
		private function gotBluntedDart( ...args ):void 
		{						
			super.shellApi.triggerEvent( _events.GOT_BLUNTED_DART, true );
			ButtonCreator.createButtonEntity( MovieClip(super._hitContainer).dart_btn, this, handleDartButtonClicked, null, null, ToolTipType.CLICK);
			restoreControl();			
		}
		
		private function startDartGame(...args):void{
			this.shellApi.loadScene(BalloonPop);			
		}
		
		private function handleDartButtonClicked(entity:Entity):void 
		{						
			startDartGame();
		} 		
		
		private function wonDartGame(...args):void 
		{						
			var actChain:ActionChain = new ActionChain( this );
			actChain.lockInput = true;				
			
			actChain.addAction( new MoveAction( player, new Point( _edgar.get(Spatial).x - 150, 1950) ) );
			actChain.addAction( new TalkAction( _edgar, "poppedBalloon" ) );
			actChain.addAction( new GetItemAction( _events.SOUVENIR_CUP, true ) );
			
			actChain.execute(this.restoreControl);			
			lockControl();
		} 
		
		
		private function guesserClicked(player:Entity, npc:Entity):void{
			if (!this.shellApi.checkEvent(_events.WON_WEIGHT)){
				Dialog(_guesser.get(Dialog)).sayById("stepUpGuess");				
				lockControl();
			}else{
				Dialog(_guesser.get(Dialog)).sayById("wonGuess");
			}
		}
		
		private function startWeightGuess():void 
		{			
			_scalemc.add(new Platform());
			Display(_scalemc.get(Display)).visible = true;
			
			lockControl();
			
			var actChain:ActionChain = new ActionChain( this );			
			
			actChain.addAction( new MoveAction( player, new Point( 320, 1290) ) );
			actChain.addAction( new TalkAction( _guesser, "guessWeightStart" ) );
			
			actChain.execute(this.rotateNeedle);
		} 
		
		private function rotateNeedle(...args):void {
			
			player.get(Spatial).x = 320;
			player.get(Spatial).y = 1230;
			
			var rot:Number; 
			if (super.shellApi.checkHasItem(_events.VIAL_OSMIUM)) rot = 175;
			else rot = 90;

			TweenUtils.entityTo(_needle, Spatial, 1,{rotation:rot, ease:Linear.easeIn, delay:.75, onComplete:finishWeightGuess});
		}
		
		private function finishWeightGuess():void 
		{			
			var actChain:ActionChain = new ActionChain( this );			
			
			if (super.shellApi.checkHasItem(_events.VIAL_OSMIUM)){
				actChain.addAction( new TalkAction( _guesser, "guessWeightWrong" ) );
				actChain.addAction( new GetItemAction( _events.SUPER_BOUNCY_BALL, true ) );
				actChain.execute(this.wonWeightGame);				
			}else{
				super.shellApi.triggerEvent( _events.NEED_WEIGHT, true );
				actChain.addAction( new TalkAction( _guesser, "guessWeightRight" ) );
				actChain.addAction( new TalkAction( _woman, "guesserCheating" ) );
				actChain.addAction( new TalkAction( player, "wantWinWeight" ) );
				actChain.execute(this.resetWeightGame);	
			}					
		} 
		
		private function resetWeightGame( ...args ):void 
		{
			_scalemc.remove(Platform);
			Display(_scalemc.get(Display)).visible = false;
			player.get(Spatial).x = 320;
			player.get(Spatial).y = 1250;
			TweenUtils.entityTo(_needle, Spatial, 1,{rotation:0, ease:Linear.easeIn});
			restoreControl();			
		} 
		
		private function wonWeightGame( ...args ):void 
		{	
			super.shellApi.triggerEvent(_events.WON_WEIGHT, true)
			resetWeightGame();		
		} 		
		
		private function foodieClicked(player:Entity, npc:Entity):void{
			trace(player+" : "+npc)
			if (this.shellApi.checkEvent(_events.GOT_FRY_OIL)){
				Dialog(_foodworker.get(Dialog)).sayById("gaveFryOil");
			}else if(super.shellApi.checkHasItem(_events.SOUVENIR_CUP) && super.shellApi.checkEvent(_events.SPOKE_ABOUT_GREASE)){
				giveFoodieCup();
			}else if(super.shellApi.checkHasItem(_events.SOUVENIR_CUP) && !super.shellApi.checkEvent(_events.SPOKE_ABOUT_GREASE)){
				Dialog(player.get(Dialog)).sayById("notThirsty");
			}else{
				Dialog(_foodworker.get(Dialog)).sayById("thanksSugar");
			}
		}		
				
		private function giveFoodieCup(...args):void 
		{			
			if (player.get(Spatial).x > _foodworker.get(Spatial).x){
				CharUtils.setDirection(player, false);
			}else{
				CharUtils.setDirection(player, true);
			}
			
			var actChain:ActionChain = new ActionChain( this );
			actChain.lockInput = true;			

			actChain.addAction( new RemoveItemAction( _events.SOUVENIR_CUP, "foodstandWorker" ) );
			actChain.addAction( new TalkAction( _foodworker, "wantSoda" ) );
			actChain.addAction( new TalkAction( player, "askFryOil" ) );
			actChain.addAction( new TalkAction( _foodworker, "giveFryOil" ) );
			actChain.addAction( new GetItemAction( _events.FRY_OIL, true ) );
			
			actChain.execute(this.gotFryOil);			
			lockControl();
		} 
		
		private function gotFryOil( ...args ):void 
		{						
			super.shellApi.removeItem(_events.SOUVENIR_CUP);
			super.shellApi.triggerEvent( _events.GOT_FRY_OIL, true );
			restoreControl();			
		} 
		
		private function handlePoolButtonClicked(entity:Entity):void	
		{
			var duckGamePopup:DuckGamePopup = super.addChildGroup( new DuckGamePopup( super.overlayContainer )) as DuckGamePopup;
		}
		
		private function lockControl(...args):void
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








