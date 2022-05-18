package game.scenes.mocktropica.poptropicaHQ.popups
{
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.ui.ToolTipType;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;

	
	public class StoryGenerator extends Popup
	{
		public function StoryGenerator(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function destroy():void
		{
			// call the super class's 'destroy()' method as well to finish cleanup of this group which removes any entites and systems specific to this group, as well as removing the groupContainer.
			SceneUtil.lockInput(this, false);
			super.destroy();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.darkenBackground = true;
			super.groupPrefix = "scenes/mocktropica/poptropicaHQ/";
			super.init(container);
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(new Array("storyGeneratorPopup.swf"));
		}
		
		// all assets ready
		override public function loaded():void
		{			
			super.screen = super.getAsset("storyGeneratorPopup.swf", true) as MovieClip;
			super.loadCloseButton();
			//super.layout.centerUI( super.screen.content );
			
			_reelArray = new Array();
			_reelArray[0] = new Array();
			_reelArray[1] = new Array();
			_reelArray[2] = new Array();
			
			_reelArray[0] = ["HIGH SCHOOL QUARTERBACK","BAKER","SPACE DRAGON","SCIENTIST","CAMP COUNSELOR","SWASHBUCKLING PIRATE","HANDSOME PROFESSOR","SHOP OWNER","HARDBOILED DETECTIVE","YOUNG GENIUS","BIG NATE","SURLY OLD MAN","CRAZY BILLIONAIRE","SPACE MARINE","LEGENDARY MONSTER","REALITY TV STAR","FORMER CHILD STAR","KNIGHT IN SHINING ARMOR","STARVING ARTIST","MINOTAUR","MAYOR","MARTIAN","POLICE OFFICER","STAND-UP COMEDIAN","UNICYCLIST","FAMOUS ASTRONAUT","MYTHOLOGICAL FIGURE","VAMPIRE","PAPER BOY","RUTHLESS DEVELOPER"];
			_reelArray[1] = ["RUBBER BAND BALL","LINT COLLECTION","FROZEN PIZZA","LAUNCH CODE","BLUEPRINT","RAY GUN","FABERGE EGG","CHEESECAKE","PUMPKIN PATCH","TREASURE MAP","LUCKY SOCK","EGYPTIAN PYRAMID","TIME MACHINE","CHOCOLATE COVERED PRETZEL","WRIST WATCH","LINT COLLECTION","HOT DOG STAND","TOENAIL COLLECTION","HOT SAUCE RECIPE","CHOCOLATE BAR","GOLDEN TICKET","PIG","COOKIE JAR","SACRED JEWEL","PAPER AIRPLANE COLLECTION","HOODED SWEATSHIRT","DONUT HOLE","CORN DOG","USED RECORD COLLECTION","VCR"];
			_reelArray[2] = ["MAYOR","OIL TYCOON","EVIL CLOWN","ELDERLY MARTIAL ARTS TEACHER","LUMBERJACK","SUPER-COMPUTER","SCIENCE TEACHER","ANGSTY TEENAGER","RED BARON","POPTROPICA CREATORS","SAMURAI WARRIOR","MUMMY","FACT MONSTER","GENTLEMAN THIEF","UNEMPLOYED ACTOR","MIME","BALLOON BOY","HIP JAZZ MUSICIAN","MEXICAN WRESTLER","CATTLE RUSTLER","CAT BURGLAR","ZOMBIE QUEEN","FILMMAKER","CIVIL WAR BUFF","QUEEN OF ENGLAND","GOBLIN KING","RECLUSIVE WRITER","SHARK","VENTRILOQUIST","MARTIAN"];
			
			var clip:MovieClip;			
			for (var i:Number =0; i< 3; i++){
				clip = MovieClip( MovieClip(super.screen.content)["reel"+i] );
				this["_reel"+i] = EntityUtils.createSpatialEntity( this, clip );
				TimelineUtils.convertClip( clip, this, this["_reel"+i], null, false );
				
				var randUint:uint = uint(Math.random() * 29);
				trace(randUint)
				Timeline(this["_reel"+i].get(Timeline)).gotoAndStop(randUint+1);
			}			
			
			clip = MovieClip( MovieClip(super.screen.content).paper );
			_paper = EntityUtils.createSpatialEntity( this, clip );
			TimelineUtils.convertClip( clip, this, _paper, null, false );			
			Timeline(_paper.get(Timeline)).gotoAndStop(1);
			Timeline(_paper.get(Timeline)).labelReached.add( labelHandler);			
			var interaction:Interaction = InteractionCreator.addToEntity(_paper, [InteractionCreator.DOWN]);
			interaction.down.add(resetSpin);
			MovieClip(super.screen.content).paper.mask = MovieClip(super.screen.content).mask_mc;
			ToolTipCreator.addToEntity(_paper, ToolTipType.TARGET);
			
			//var button:Entity = ButtonCreator.createButtonEntity( MovieClip(super.screen.content).handle, this, spinReels );			
			clip = MovieClip( MovieClip(super.screen.content).handle);
			_handle = EntityUtils.createSpatialEntity( this, clip );
			TimelineUtils.convertClip( clip, this, _handle, null, false );			
			Timeline(_handle.get(Timeline)).gotoAndStop(1);
			var winteraction:Interaction = InteractionCreator.addToEntity(_handle, [InteractionCreator.DOWN]);
			winteraction.down.add(spinReels);			
			ToolTipCreator.addToEntity(_handle, ToolTipType.CLICK);	
			
			_reel1SoundEntity = AudioUtils.createSoundEntity("_reel1SoundEntity");	
			_reel1Audio = new Audio();
			_reel1SoundEntity.add(_reel1Audio);			
			super.addEntity(_reel1SoundEntity);
			_reel2SoundEntity = AudioUtils.createSoundEntity("_reel2SoundEntity");	
			_reel2Audio = new Audio();
			_reel2SoundEntity.add(_reel2Audio);			
			super.addEntity(_reel2SoundEntity);
			_reel3SoundEntity = AudioUtils.createSoundEntity("_reel3SoundEntity");	
			_reel3Audio = new Audio();
			_reel3SoundEntity.add(_reel3Audio);			
			super.addEntity(_reel3SoundEntity);
			_handleSoundEntity = AudioUtils.createSoundEntity("_handleSoundEntity");	
			_handleAudio = new Audio();
			_handleSoundEntity.add(_handleAudio);			
			super.addEntity(_handleSoundEntity);
			_paperSoundEntity = AudioUtils.createSoundEntity("_paperSoundEntity");	
			_paperAudio = new Audio();
			_paperSoundEntity.add(_paperAudio);			
			super.addEntity(_paperSoundEntity);
			_stopReelSoundEntity = AudioUtils.createSoundEntity("_stopReelSoundEntity");	
			_stopReelAudio = new Audio();
			_stopReelSoundEntity.add(_stopReelAudio);			
			super.addEntity(_stopReelSoundEntity);

			super.loaded();
		}
		
		private function labelHandler( label:String ):void
		{
			if (label == "end"){
				MovieClip(super.screen.content).paper.mask = null;
				MovieClip(super.screen.content).mask_mc.visible = false;
				SceneUtil.addTimedEvent( this, new TimedEvent( .3, 1, resetInput ));
				
			}

		}
		
		private function resetInput():void
		{
			SceneUtil.lockInput(this, false);
		}
		
		private function spinReels(...args):void
		{					
			SceneUtil.lockInput(this, true);
			Timeline(_handle.get(Timeline)).gotoAndPlay(2);				
			
			for (var i:Number =0; i< 3; i++){
				Timeline(this["_reel"+i].get(Timeline)).play();
			}	
			
			_handleAudio.play(SoundManager.EFFECTS_PATH + "gears_04a.mp3");
			_reel1Audio.play(SoundManager.EFFECTS_PATH + "gears_06_loop.mp3", true);
			_reel2Audio.play(SoundManager.EFFECTS_PATH + "gears_14_loop.mp3", true);
			_reel3Audio.play(SoundManager.EFFECTS_PATH + "gears_15_loop.mp3", true);
			
			SceneUtil.addTimedEvent( this, new TimedEvent( randomRange(1 , 1.5), 1, completeSpin0 ));
			SceneUtil.addTimedEvent( this, new TimedEvent( randomRange(1.75 , 2.25), 1, completeSpin1 ));
			SceneUtil.addTimedEvent( this, new TimedEvent( randomRange(2.5 , 3), 1, completeSpin2 ));				
		}
		
		private function completeSpin0():void{
			Timeline(_reel0.get(Timeline)).stop();
			_reel1Audio.stop(SoundManager.EFFECTS_PATH + "gears_06_loop.mp3");
			_stopReelAudio.play(SoundManager.EFFECTS_PATH + "gears_07.mp3");
		}
		
		private function completeSpin1():void
		{
			Timeline(_reel1.get(Timeline)).stop();
			_reel2Audio.stop(SoundManager.EFFECTS_PATH + "gears_14_loop.mp3");
			_stopReelAudio.play(SoundManager.EFFECTS_PATH + "gears_11.mp3");
		}
		
		private function completeSpin2():void
		{
			Timeline(_reel2.get(Timeline)).stop();			
			SceneUtil.addTimedEvent( this, new TimedEvent( .5, 1, printPaper ));
			_reel3Audio.stop(SoundManager.EFFECTS_PATH + "gears_15_loop.mp3");
			_stopReelAudio.play(SoundManager.EFFECTS_PATH + "gears_12.mp3");
		}
		
		private function printPaper():void
		{
			
			trace(Timeline(_reel0.get(Timeline)).currentIndex+" : "+ Timeline(_reel1.get(Timeline)).currentIndex +" : "+ Timeline(_reel2.get(Timeline)).currentIndex )
			trace(_reelArray[0][Timeline(_reel0.get(Timeline)).currentIndex].toLowerCase()+" : "+_reelArray[1][Timeline(_reel1.get(Timeline)).currentIndex].toLowerCase()+" : "+_reelArray[2][Timeline(_reel2.get(Timeline)).currentIndex].toLowerCase())
			
			MovieClip(_paper.get(Display).displayObject).paper_mc.t0.text = _reelArray[0][Timeline(_reel0.get(Timeline)).currentIndex].toLowerCase();
			MovieClip(_paper.get(Display).displayObject).paper_mc.t1.text = _reelArray[1][Timeline(_reel1.get(Timeline)).currentIndex].toLowerCase();
			MovieClip(_paper.get(Display).displayObject).paper_mc.t2.text = _reelArray[2][Timeline(_reel2.get(Timeline)).currentIndex].toLowerCase();
			
			Timeline(_paper.get(Timeline)).gotoAndPlay(2);
			_paperAudio.play(SoundManager.EFFECTS_PATH + "print_paper_03.mp3");
		}
		
		private function resetSpin(...args):void
		{
			Timeline(_paper.get(Timeline)).gotoAndPlay("throw");
			SceneUtil.addTimedEvent( this, new TimedEvent( .3, 1, finishReset ));
			SceneUtil.lockInput(this, true);
		}
		
		private function finishReset():void
		{
			MovieClip(super.screen.content).paper.mask = MovieClip(super.screen.content).mask_mc;
			MovieClip(super.screen.content).mask_mc.visible = true;
			Timeline(_paper.get(Timeline)).gotoAndStop(1);
			SceneUtil.lockInput(this, false);
		}
		
		private function randomRange(minNum:Number, maxNum:Number):Number 
		{
			var number:Number = (Math.random() * (maxNum - minNum)) + minNum;
			return (number);
		}
		
		private var _reelArray:Array;
		private var _reel0:Entity;
		private var _reel1:Entity;
		private var _reel2:Entity;
		private var _paper:Entity;
		private var _handle:Entity;
		
		private var _reel1SoundEntity:Entity;
		private var _reel2SoundEntity:Entity;
		private var _reel3SoundEntity:Entity;
		private var _handleSoundEntity:Entity;
		private var _paperSoundEntity:Entity;
		private var _stopReelSoundEntity:Entity;
		private var _reel1Audio:Audio;
		private var _reel2Audio:Audio;
		private var _reel3Audio:Audio;
		private var _handleAudio:Audio;
		private var _paperAudio:Audio;
		private var _stopReelAudio:Audio;
	}
}



