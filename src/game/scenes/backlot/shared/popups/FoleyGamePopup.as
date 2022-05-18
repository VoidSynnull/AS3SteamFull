package game.scenes.backlot.shared.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.filters.ColorMatrixFilter;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.scenes.backlot.BacklotEvents;
	import game.data.ui.ToolTipType;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	public class FoleyGamePopup extends Popup
	{
		public function FoleyGamePopup(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		private var backlot:BacklotEvents;
		private var movies:Array = ["foleyMovie1.swf","foleyMovie2.swf","foleyMovie3.swf","foleyMovie4.swf"];
		private var buttons:Array = ["bear","gorilla","plates","clop","balloon","wind","kick","fan","ghost", "buffalo","flare","train","stomp","splash","thunder","rain"];
		private var buttonGroups:Array = [[15,14,4,13],[10,2,0,8],[9,3,11,6],[7,12,1,5]];
		private var movieNumber:int = 0;
		private var soundOnTime:Array = [false, false, false, false];
		private var eventNumber:int = 0;
		private var currentEvent:String = "";
		
		private const levelOn:int = 0;
		private const levelOff:int = -150;
		
		private var content:MovieClip;
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.groupPrefix = "scenes/backlot/postProduction/foleyGamePopup/";
			super.screenAsset = "foleyGame.swf";
			
			super.darkenBackground = true;
			super.init(container);
			load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			
			content = screen.content as MovieClip;
			
			super.layout.centerUI(content);
			
			setUp();
			
			super.loadCloseButton();
		}
		
		private function setUp():void
		{
			setUpButtons();
			setUpFeedBack();
			setUpInstructions();
		}
		
		private function startGame(entity:Entity):void
		{
			Display(getEntityById("startInstructions").get(Display)).visible = false;
			loadMovie();
		}
		
		private function resetMovie():void
		{
			for(var i:int = 0; i < soundOnTime.length; i++)
			{
				soundOnTime[i] = false;
			}
			eventNumber = 0;
			var movie:Entity = getEntityById("movie"+movieNumber);
			Display(movie.get(Display)).visible = false;
			Display(getEntityById("soundIndicator").get(Display)).visible = false;
			SceneUtil.addTimedEvent(this, new TimedEvent(2,1,retry));
			resetButtons();
		}
		
		private function retry():void
		{
			var movie:Entity = getEntityById("movie"+movieNumber);
			Timeline(movie.get(Timeline)).gotoAndPlay(0);
			Display(movie.get(Display)).visible = true;
			activateButtons();
		}
		
		private function loadMovie():void
		{
			loadFile(movies[movieNumber],movieLoaded);
		}
		
		private function movieLoaded(clip:DisplayObjectContainer):void
		{
			var movieClip:MovieClip = clip as MovieClip;
			var movie:Entity = EntityUtils.createSpatialEntity(this,clip,content.smMovie);
			movie.add(new Id("movie"+movieNumber));
			TimelineUtils.convertClip(movieClip,this,movie,null,false);
			Timeline(movie.get(Timeline)).labelReached.add(Command.create(movieLabelHandler,movie.get(Timeline)));
			resetMovie();
		}
		
		private function setUpInstructions():void
		{
			var startInstructions:Entity = EntityUtils.createSpatialEntity(this,content.startInstructions,content);
			startInstructions.add(new Id("startInstructions"));
			
			var button:MovieClip = content.startInstructions.btnStart;
			
			var startButton:Entity = EntityUtils.createSpatialEntity(this, button, content.startInstructions);
			var interaction:Interaction = InteractionCreator.addToEntity(startButton,[InteractionCreator.CLICK],button);
			interaction.click.add(startGame);
			
			var winScreen:Entity = EntityUtils.createSpatialEntity(this,content.winScreen,content);
			winScreen.add(new Id("winScreen"));
			Display(winScreen.get(Display)).visible = false;
		}
		
		private function setUpFeedBack():void
		{
			var soundIndicator:Entity = EntityUtils.createSpatialEntity(this,content.soundIndicator,content);
			soundIndicator.add(new Id("soundIndicator"));
			Display(soundIndicator.get(Display)).visible = false;
			
			var notGoodClip:MovieClip = content.notGood;
			var notGood:Entity = EntityUtils.createSpatialEntity(this, notGoodClip,content);
			notGood.add(new Id("notGood"));
			TimelineUtils.convertClip(notGoodClip,this,notGood,null,false);
			var time:Timeline = notGood.get(Timeline);
			time.labelReached.add(Command.create(notGoodListener,time));
			
			var good:Entity = EntityUtils.createSpatialEntity(this, content.good,content);
			good.add(new Id("good"));
			TimelineUtils.convertClip(content.good,this,good,null,false);
			time = good.get(Timeline);
			time.labelReached.add(Command.create(goodListener,time));
		}
		
		private function goodListener(label:String, timeline:Timeline):void
		{
			if(label == "ending")
				timeline.gotoAndStop(0);
		}
		
		private function notGoodListener(label:String, timeline:Timeline):void
		{
			if(label == "ending")
			{
				timeline.gotoAndStop(0);
				resetMovie();
			}
		}
		
		private function setUpButtons():void
		{
			for(var i:int = 0; i < buttons.length; i++)
			{
				var buttonClip:MovieClip = content[buttons[i]+"Btn"];
				buttonClip.stop();
				var button:Entity = EntityUtils.createSpatialEntity(this,buttonClip,content);
				button.add(new Id(buttons[i]));
				
				TimelineUtils.convertClip(buttonClip,this,button,null,false);
				var time:Timeline = button.get(Timeline);
				time.labelReached.add(Command.create(buttonLabelHandler,time));
				
				InteractionCreator.addToEntity(button,[InteractionCreator.CLICK],buttonClip);
				
				setButtonBrightness(buttonClip, levelOff);
			}
		}
		
		private function activateButtons():void
		{
			for(var i:int = 0; i < buttonGroups[movieNumber].length; i++)
			{
				var button:Entity = getEntityById(buttons[buttonGroups[movieNumber][i]]);
				
				Interaction(button.get(Interaction)).click.add(clickButton);
				
				var buttonClip:MovieClip = Display(button.get(Display)).displayObject as MovieClip;
				
				setButtonBrightness(buttonClip, levelOn);
				
				ToolTipCreator.addToEntity(button);
			}
		}
		
		private function resetButtons():void
		{
			for(var i:int = 0; i < buttons.length; i++)
			{
				removeButtonInteraction(getEntityById(buttons[i]));
			}
		}
		
		private function removeButtonInteraction(button:Entity):void
		{
			var buttonClip:MovieClip = Display(button.get(Display)).displayObject as MovieClip;
			setButtonBrightness(buttonClip, levelOff);
			ToolTipCreator.addToEntity(button, ToolTipType.ARROW);
			Interaction(button.get(Interaction)).click.removeAll();
		}
		
		private function setButtonBrightness(button:MovieClip, level:int):void
		{
			var myElements_array:Array = 
				[1, 0, 0, 0, level,
				0, 1, 0, 0, level,
				0, 0, 1, 0, level,
				0, 0, 0, 1, 0];
			
			var myColorMatrix_filter:ColorMatrixFilter = new ColorMatrixFilter(myElements_array);
			
			button.filters = [myColorMatrix_filter];	
		}
		
		private function clickButton(button:Entity):void
		{
			removeButtonInteraction(button);
			
			Timeline(button.get(Timeline)).gotoAndPlay(0);
			
			if(currentEvent == button.get(Id).id)
			{
				AudioUtils.play(this,"effects/ping_04.mp3");
				var good:Entity = getEntityById("good");
				Timeline(good.get(Timeline)).gotoAndPlay(0);
				soundOnTime[eventNumber] = true;
			}
			else
			{
				AudioUtils.play(this,"effects/buzzer_01.mp3");
				var movie:Entity = getEntityById("movie"+movieNumber);
				Timeline(movie.get(Timeline)).stop();
				if(currentEvent == "")
				{
					showErrorMessage(2);
				}
				else
				{
					showErrorMessage(1);
				}
			}
		}
		
		private function buttonLabelHandler(label:String, timeline:Timeline):void
		{
			if(label == "ending")
				timeline.gotoAndStop(0);
		}
		
		private function movieLabelHandler(label:String, timeline:Timeline):void
		{
			if(label == "beginning")
				return;
			if(label == "ending")
			{
				timeline.gotoAndStop(timeline.currentIndex);
				var madeAllNoises:Boolean = true;
				for(var i:int = 0; i < soundOnTime.length; i++)
				{
					if(soundOnTime[i] == false)
					{
						madeAllNoises = false;
						break;
					}
				}
				if(madeAllNoises)
				{
					if(movieNumber + 1 < movies.length)
					{
						SceneUtil.addTimedEvent(this,new TimedEvent(1,1, loadNextMovie));
					}
					else
					{
						var winScreen:Entity = getEntityById("winScreen");
						Display(winScreen.get(Display)).visible = true;
						SceneUtil.addTimedEvent(this,new TimedEvent(1,1, win));
					}
				}
				else
				{
					showErrorMessage(3);
				}
				return;
			}
			
			var eventType:String = label.substring(0,3);
			var event:String = label.substring(4);
			
			var soundIndicator:Entity = getEntityById("soundIndicator");
			
			if(eventType == "beg")
			{
				currentEvent = event;
				Display(soundIndicator.get(Display)).visible = true;
			}
			else
			{
				eventNumber ++;
				currentEvent = "";
				Display(soundIndicator.get(Display)).visible = false;
			}
		}
		
		private function win():void
		{
			shellApi.triggerEvent(backlot.COMPLETE_FOLEY, true);
			super.close();
		}
		
		private function loadNextMovie():void
		{
			removeEntity(getEntityById("movie"+movieNumber));
			movieNumber++;
			loadMovie();
		}
		
		private function showErrorMessage(errorNumber:int):void
		{
			var notGood:Entity = getEntityById("notGood");
			var notGoodClip:MovieClip = Display(notGood.get(Display)).displayObject as MovieClip;
			notGoodClip.gotoAndStop(2);
			
			for(var m :int = 1; m <= 3; m++)
			{
				notGoodClip["message"+m].visible = false;
			}
			
			notGoodClip["message"+errorNumber].visible = true;
			
			Timeline(notGood.get(Timeline)).gotoAndPlay(2);
		}
		
		override public function close( removeOnClose:Boolean = true, onCloseHandler:Function = null ):void
		{
			super.close();
		}
	}
}