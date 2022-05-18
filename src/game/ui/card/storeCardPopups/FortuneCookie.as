package game.ui.card.storeCardPopups
{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.text.TextField;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.timeline.Timeline;
	import game.creators.ui.ButtonCreator;
	import game.ui.popup.Popup;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.TextUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	public class FortuneCookie extends Popup
	{
		private var tf:TextField;
		private var fortune:Entity;
		private var cookie:Entity;
		private var cookieBounce:Timeline;
		private var cookieBroke:Entity;
		private var crunch:Entity;
		
		private var content:MovieClip;
		
		public function FortuneCookie(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			super.init(container);
			darkenBackground = true;
			groupPrefix = "ui/card/storeCardPopups/";
			screenAsset = "fortuneCookie.swf";
			super.load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			content = screen.content;
			fitToDimensions(content);
			var clip:MovieClip = content["bg"];
			clip.width = shellApi.viewportWidth / content.scaleX;
			clip.height = shellApi.viewportHeight / content.scaleY;
			
			clip = content["fortune"];
			tf = TextUtils.refreshText(clip.removeChild(clip["label"]) as TextField,"Billy Serif");
			
			if(PlatformUtils.isMobileOS)
				convertContainer(content);
			
			clip.addChild(tf);
			
			fortune = EntityUtils.createSpatialEntity(this, clip);
			EntityUtils.visible(fortune, false, true);
			var spatial:Spatial = fortune.get(Spatial);
			spatial.scaleX = spatial.scaleY = .01;
			
			clip = content["crunch"];
			crunch = EntityUtils.createSpatialEntity(this, clip);
			TimelineUtils.convertClip(content["crunch"], this, crunch);
			
			clip = content["cookieBroke"];
			cookieBroke = EntityUtils.createSpatialEntity(this, clip);
			Display(cookieBroke.get(Display)).alpha = 0;
			
			clip = content["cookie"];
			cookie = EntityUtils.createSpatialEntity(this, clip);
			cookieBounce = TimelineUtils.convertClip(clip, this, cookie).get(Timeline);
			cookieBounce.handleLabel("ending", chill, false);
			chill();
			
			clip = content["click"];
			var btn:Entity = ButtonCreator.createButtonEntity(clip, this, openCookie);
			loadCloseButton();
		}
		
		private function chill():void
		{
			cookieBounce.gotoAndStop(0);
			SceneUtil.delay(this, 1 + Math.random(), cookieBounce.play);
		}
		
		private function openCookie(entity:Entity):void
		{
			removeEntity(entity);
			cookieBounce.removeLabelHandler(chill);
			
			TweenUtils.entityTo(cookie, Display, .8, {alpha:0});
			TweenUtils.entityTo(cookieBroke, Display, .8, {alpha:1});
			var time:Timeline = crunch.get(Timeline);
			time.handleLabel("ending", showFortune);
			time.play();
		}
		
		private function showFortune():void
		{
			EntityUtils.visible(fortune);
			tf.text = FORTUNES[int(Math.random() * FORTUNES.length)];
			TweenUtils.entityTo(fortune, Spatial, 2, {rotation:720, scaleX:1, scaleY:1, ease:Quad.easeIn});
		}
		
		private static var FORTUNES:Array = ["You will see a friend soon.", 
			"Creativity is the path to success.", 
			"Someone is thinking about you.", 
			"Friendship should never be taken for granted.", 
			"Helping others is its own reward.", 
			"Practice makes perfect.", 
			"Coconut milk makes booga sharks happy.", 
			"Open more cookies\r get more fortunes!", 
			"Someone misses you.", 
			"Phew! It was getting hot in there.", 
			"You will discover a hidden talent.", 
			"When times are difficult\r you will find strength.", 
			"Love is on the rise!", 
			"The shortest distance between 2 points is a straight line.", 
			"Homework is neither home\r nor work. Discuss!", 
			"You will succeed in achieving your goals!", 
			"An opportunity will present itself soon. Go for it!", 
			"Smile! Even an evil genius like Dr. Hare smiles.", 
			"A bad start doesn't dictate a bad ending.", 
			"Time will tell you everything.", 
			"No one likes problems. Everyone likes solutions.", 
			"Help I am a prisoner in a Fortune Cookie Factory.", 
			"Bald is beautiful\r just ask ask Director D.", 
			"A lotus flower is only as beautiful as the beholder (I have no clue what that means).", 
			"Have a nice day! :)", 
			"Give a man a fish stick and he'll be full for a day\r teach a man to buy fish sticks and he'll be full for the rest of his life.", 
			"Stop and smell the roses\r but watch out for thorns.", 
			"Your future is only as bright as your today.", 
			"Dare to be yourself\r and you'll be happy.", 
			"Popularity shatters. Integrity remains unbroken.", 
			"Life is a race\r but some of us have better running shoes.", 
			"Life is like a raisin.  You shrivel up and get old.", 
			"Think of your freckles as a close friend and you will never be alone.", 
			"Your future is like honey. It will be sticky at times but very sweet.", 
			"Beware of eating dog food. It will give you bad breath.", 
			"You will find lots of chewing gum in your future...under your desk.", 
			"Look for the good in others and you will see the good in yourself.", 
			"Someone secretly admires you and you will never know who.", 
			"Help someone when they are low and it will make you feel high.", 
			"This fortune cookie is inhabited by a family of ants.", 
			"Watch out for a man wearing a yellow hat with a monkey.", 
			"When life throws you a punch in the face\r duck!", 
			"Always take time to smell the chocolate chip cookies.", 
			"Beware of Ninjas on bicycles.", 
			"This fortune cookie is about 20 years old.  Don't eat it.", 
			"You shouldn't believe everything you read.", 
			"Don't take advice from someone in a clown suit.", 
			"Smile at someone and then see what happens.", 
			"If life hands you a lemon\r add sugar\r cold water\r and then sell it at a lemonade stand.", 
			"Life is like riding a bicycle so don't forget to wear a helmet.", 
			"Don't waste your time chasing after fruitless dreams.  Instead dream about chasing wasted fruit.", 
			"The Obstacle is the Path.",
			"Captain Crawfish will return.",
			"If you keep throwing dirt at others soon you'll have no ground to stand on.",
			"A person who is wise\r knows they are foolish.",
			"The answers to all your questions can be found within...or on the internet.",
			"Make like a banana and split!",
			"Will you choose to be famous or infamous?",
			"Hazmat Hermit was here!",
			"The Black Widow stole your fortune.",
			"A tough choice lies in your future.",
			"Zeus is watching\r so be nice!",
			"Believe in yourself and others will believe in you.",
			"Why would you trust your future to a fortune cookie?",
			"A man who runs behind a car gets exhausted. A man who runs in front of a car gets tired.",
			"Save the planet\r recycle this fortune."];	
	}
}