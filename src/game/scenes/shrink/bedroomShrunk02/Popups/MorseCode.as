package game.scenes.shrink.bedroomShrunk02.Popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.components.motion.FollowTarget;
	import game.components.timeline.Timeline;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Walk;
	import game.scene.template.CharacterGroup;
	import game.scenes.shrink.ShrinkEvents;
	import game.ui.popup.Popup;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TextUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	public class MorseCode extends Popup
	{
		public function MorseCode(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.groupPrefix = "scenes/shrink/bedroomShrunk02/";
			super.screenAsset = "morse_code.swf";
			
			super.darkenBackground = true;
			super.init(container);
			load();
		}
		
		override public function load():void
		{
			super.loadFiles(["npcs.xml"]);
			super.load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			
			this.bitmapAssets();
			
			setUp();
			
			super.loadCloseButton();
		}
		
		private var content:MovieClip;
		
		private var morseCode:Array = [[0,1],[1,0,0,0],[1,0,1,0],[1,0,0],[0],//a,b,c,d,e,
										[0,0,1,0],[1,1,0],[0,0,0,0],[0,0],[0,1,1,1],//f,g,h,i,j,
										[1,0,1],[0,1,0,0],[1,1],[1,0],[1,1,1,1],//k,l,m,n,o,
										[0,1,1,0],[1,1,0,1],[0,1,0],[0,0,0],[1],//p,q,r,s,t,
										[0,0,1],[0,0,0,1],[0,1,1],[1,0,0,1],[1,0,1,1],[1,1,0,0]];//u,v,w,x,y,z
		
		private const alphabet:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
		
		private const FIRST_MESSAGE:String = "FLUSH THE THUMB DRIVE";
		
		private const SECOND_MESSAGE:String = "THIEF IS MR SILVA";
		
		private var message:String;
		private var messageIndex:int = 0;
		private var codeIndex:int = 0;
		private var currentCode:Array;
		private var currentLetter:String;
		private var output:TextField;
		private var answer:TextField;
		private var outputDisplay:Entity;
		
		private var outputs:Vector.<String>;
		
		private var flashLight:Timeline;
		
		private var flashNames:Array = ["Short","Long"];
		
		private var shrink:ShrinkEvents;
		
		private function bitmapAssets():void
		{
			this.createBitmap(this.screen.content.instructions, 2);
			this.createBitmap(this.screen.content.letterBackground);
			this.createBitmap(this.screen.content.paper);
			this.createBitmap(this.screen.content.building);
			this.createBitmap(this.screen.content.window);
		}
		
		private function setUp():void
		{
			content = screen.content;
			//content.x = shellApi.camera.camera.viewportWidth / 2;
			//content.y = shellApi.camera.camera.viewportHeight / 2;
			
			var rectangle:Rectangle = new Rectangle(0, 0, 746, 532);
			rectangle.inflate(50, 50);
			this.letterbox(content, rectangle, false);
			
			sendingMessage = wrongFeedBack = true;
			
			setUpFlashLight();
			setUpLetters();
			setUpRepeatButton();
			setUpOutPut();
			
			if(shellApi.checkEvent(shrink.GOT_CJS_MESSAGE_01) || shellApi.checkEvent(shrink.FLUSHED_THUMB_DRIVE))
				message = SECOND_MESSAGE;
			else
				message = FIRST_MESSAGE;
			
			setUpMrSilva();
			
			sendLetterCode();
		}
		
		private var charGroup:CharacterGroup;
		private var silva:Entity;
		
		private function setUpMrSilva():void
		{
			var clip:MovieClip = content["char1"];
			if(message == FIRST_MESSAGE)
				content.removeChild(clip);
			else
			{
				charGroup = new CharacterGroup();
				charGroup.setupGroup(this, clip, getData("npcs.xml"), allCharactersLoaded);
			}
		}
		
		private function allCharactersLoaded():void
		{
			silva = getEntityById("silva");
		}
		
		private function setUpOutPut():void
		{
			answer = TextUtils.refreshText(content["answerTxt"], "CreativeBlock BB");
			output = TextUtils.refreshText(content["outputTxt"],"CreativeBlock BB");
			outputDisplay = EntityUtils.createSpatialEntity(this, output, content);
			EntityUtils.visible(outputDisplay, false);
			outputs = new Vector.<String>();
			outputs.push("Nope. Try again.", "Close, but not the right letter.", "Let's try that again.");
		}
		
		private function setUpRepeatButton():void
		{
			var clip:MovieClip = content["repeatButton"];
			ButtonCreator.createButtonEntity(clip, this, repeatSignal, null, null, null, true, true, 2);
		}
		
		private function repeatSignal(button:Entity):void
		{
			sendLetterCode();
		}
		
		private function setUpLetters():void
		{
			var buttons:MovieClip = content.buttonHolder;
			
			var clip:MovieClip = buttons["xClip"];
			var sprite:Sprite = this.createBitmapSprite(clip, 2);
			
			var wrongLetter:Entity = EntityUtils.createSpatialEntity(this, sprite, buttons);
			wrongLetter.add(new FollowTarget(wrongLetter.get(Spatial))).add(new Id("xClip"));
			Display(wrongLetter.get(Display)).alpha = 0;
			
			for(var i:int = 0; i < 26; i++)
			{
				clip = buttons["button"+alphabet.charAt(i)];
				
				//clip.parent.removeChild(clip);
				//continue;
				
				var button:Entity = ButtonCreator.createButtonEntity(clip, this, Command.create(clickLetter,alphabet.charAt(i), wrongLetter), null, null, null, true, true, 2);
				button.add(new Id(clip.name));
			}
		}
		
		private function hoverLetter(button:Entity = null):void
		{
			if(sendingMessage || wrongFeedBack)
				return;
			for(var i:int = 0; i < 26; i++)
			{
				Timeline(getEntityById("button"+alphabet.charAt(i)).get(Timeline)).gotoAndStop(0);
			}
			if(button != null)
				Timeline(button.get(Timeline)).gotoAndStop(1);
		}
		
		private function clickLetter(button:Entity, letter:String, wrongLetter:Entity):void
		{
			Timeline(button.get(Timeline)).gotoAndStop(0);
			if(sendingMessage || wrongFeedBack)
				return;
			if(letter != currentLetter)
			{
				FollowTarget(wrongLetter.get(FollowTarget)).target = button.get(Spatial);
				Display(wrongLetter.get(Display)).alpha = 1;
				output.text = outputs[int(Math.random() * 3)];
				EntityUtils.visible(outputDisplay);
				SceneUtil.delay(this, 2, Command.create(fadeFeedBack, wrongLetter));
				wrongFeedBack = true;
			}
			else
			{
				writeDownCode(letter);
				messageIndex++;
				sendLetterCode();
			}
		}
		
		private function fadeFeedBack(wrongLetter:Entity):void
		{
			TweenUtils.entityTo(wrongLetter, Display, 1, {alpha:0, onComplete:Command.create(hideMessage, wrongLetter)});
		}
		
		private function hideMessage(wrongLetter:Entity):void
		{
			var spatial:Spatial = wrongLetter.get(Spatial);
			wrongLetter.get(FollowTarget).target = spatial;
			spatial.x = spatial.y = 0;
			EntityUtils.visible(outputDisplay, false);
			sendLetterCode();
		}
		
		private function setUpFlashLight():void
		{
			flashLight = TimelineUtils.convertClip(content.flashlight,this,null,null,false).get(Timeline);
			flashLight.labelReached.add(flashes);
		}
		
		private function flashes(label:String):void
		{
			if(label == "StopShort" || label == "ending")
			{
				flashLight.stop();
				playLetter();
			}
		}
		
		private var sendingMessage:Boolean;
		private var wrongFeedBack:Boolean;
		
		private function sendLetterCode():void
		{
			hoverLetter();
			sendingMessage = true;
			wrongFeedBack = false;
			SceneUtil.addTimedEvent(this, new TimedEvent(2,1,getLetter));
		}
		
		private function getLetter():void
		{
			if(messageIndex < message.length)
				currentLetter = message.charAt(messageIndex);
			else
			{
				trace("you got the message");
				if(message == SECOND_MESSAGE)
					silvaWalkRight();
				else
					returnToGame();
				return;
			}
			if(currentLetter == " ")
			{
				writeDownCode(currentLetter);
				currentLetter = message.charAt(++messageIndex);
				currentCode = getCode(currentLetter);
			}
			else
				currentCode = getCode(currentLetter);
			playLetter();
		}
		
		private function playLetter():void
		{
			if(codeIndex >= currentCode.length)
			{
				SceneUtil.lockInput(this, false);
				codeIndex = 0;
				trace("end of the morse code for the letter");
				sendingMessage = false;
				return;
			}
			var code:int = currentCode[codeIndex];
			flashLight.gotoAndPlay(flashNames[code]);
			codeIndex++;
		}
		
		private function writeDownCode(letter:String):void
		{
			answer.text += letter;
		}
		
		private function getCode(letter:String):Array
		{
			var index:int = alphabet.indexOf(letter);
			return morseCode[index];
		}
		
		private function silvaWalkRight():void
		{
			SceneUtil.lockInput( this );
			CharUtils.setAnim( silva, Walk );
			TweenUtils.entityTo( silva, Spatial, 2.5, { x : 200, onComplete : silvaStand });
		}
		
		private function silvaStand():void
		{
			CharUtils.setAnim(silva, Stand);
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, silvaWalkLeft));
		}
		
		private function silvaWalkLeft():void
		{
			CharUtils.setAnim( silva, Walk );
			CharUtils.setDirection(silva, false);
			TweenUtils.entityTo( silva, Spatial, 3, { x : 0, onComplete : returnToGame });
		}
		
		private function returnToGame(...args):void
		{
			SceneUtil.lockInput(this, false);
			if(message == FIRST_MESSAGE)
				shellApi.triggerEvent(shrink.GOT_CJS_MESSAGE_01, true);
			else
				shellApi.triggerEvent(shrink.GOT_CJS_MESSAGE_02, true);
			super.close();
		}
	}
}