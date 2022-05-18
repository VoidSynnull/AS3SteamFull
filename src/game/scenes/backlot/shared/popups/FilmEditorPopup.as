package game.scenes.backlot.shared.popups
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.motion.FollowTarget;
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.scenes.backlot.BacklotEvents;
	import game.scenes.backlot.postProduction.ScrollingSystem.Scroll;
	import game.scenes.backlot.postProduction.ScrollingSystem.ScrollControl;
	import game.scenes.backlot.postProduction.ScrollingSystem.ScrollControlSystem;
	import game.scenes.backlot.postProduction.ScrollingSystem.ScrollSystem;
	import game.scenes.backlot.postProduction.SliderSystem.Slider;
	import game.scenes.backlot.postProduction.SliderSystem.SliderSystem;
	import game.scenes.backlot.postProduction.drawingSystem.Draw;
	import game.scenes.backlot.postProduction.drawingSystem.DrawSystem;
	import game.systems.SystemPriorities;
	import game.ui.popup.Popup;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	public class FilmEditorPopup extends Popup
	{
		public function FilmEditorPopup(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.groupPrefix = "scenes/backlot/postProduction/filmEditorPopup/";
			super.screenAsset = "FilmEditorPopup.swf";
			
			super.darkenBackground = true;
			super.init(container);
			load();
		}
		
		private var backlot:BacklotEvents;
		private var content:MovieClip;
		private const clipsPerStrip:int = 4;
		private var clipsLoaded:int = 0;
		private var labels:Array = ["init","play","gameLostBadCut","gameLostWrongFrame","gameWon"];
		private var razorInitPosition:Point;
		private var currentStrip:int = 0;
		private var holdingRazor:Boolean = false;
		private var cuttingArea:Rectangle;
		private var inMenu:Boolean = false;
		private var cutZoneNumber:int = 0;
		private var cutArea:Rectangle;
		private var reelsComplete:Array = [false, false, false];
		private var score:int = 0;
		
		private var canvas:MovieClip;
		
		override public function loaded():void
		{
			super.loaded();
			
			addSystem(new SliderSystem(), SystemPriorities.update);
			addSystem(new ScrollSystem(), SystemPriorities.update);
			addSystem(new ScrollControlSystem(), SystemPriorities.update);
			addSystem(new DrawSystem(), SystemPriorities.update);
			setUp();
			
			super.loadCloseButton();
		}
		
		private function setUp():void
		{
			clipsLoaded = 0;
			holdingRazor = false;
			content = screen.content as MovieClip;
			
			content.scaleX = shellApi.camera.camera.viewportWidth / 640;
			content.scaleY = shellApi.camera.camera.viewportHeight / 480;
			
			content.stop();
			
			shellApi.inputEntity.add(new Draw(null, 2, 0xFF0000, null, new Point(1/content.scaleX, 1/content.scaleY)));
			Draw(shellApi.inputEntity.get(Draw)).outSideLimits.add(checkIfCutWasBad);
			
			setUpStrips();
			var shadow:Entity = EntityUtils.createDisplayEntity(this, content.shadow, content);
			cuttingArea = new Rectangle(content.shadow.x * content.scaleX, content.shadow.y * content.scaleY, content.shadow.width * content.scaleX, content.shadow.height * content.scaleY);
			
			setUpInstructions();
			
			setUpRazor();
		}
		
		private function checkIfCutWasBad(bounds:Rectangle, point:Point):void
		{
			if(point.y < bounds.top || point.y > bounds.bottom)
			{
				Draw(shellApi.inputEntity.get(Draw)).penDown = false;
				returnRazor(getEntityById("razor"));
				setInstructions(labels[2]);//bad cut
				return;
			}
			var rect:Rectangle = canvas.getBounds(canvas);
			trace(rect + " " + bounds);
			
			var buffer:Number = 1;
			
			if(rect.left < bounds.left - buffer &&  rect.right > bounds.right + buffer)
			{
				makeTheCut();
				trace("you cut the strip");
			}
		}
		
		private function makeTheCut():void
		{
			Draw(shellApi.inputEntity.get(Draw)).erase();
			Display(getEntityById("cut_zone_"+cutZoneNumber+"_"+currentStrip).get(Display)).visible = false;
			cutZoneNumber++;
			if(cutZoneNumber > 1)
			{
				checkIfWasRightClip();
			}
			else
			{
				setUpCuttingZone();
				Display(getEntityById("cut_zone_"+cutZoneNumber+"_"+currentStrip).get(Display)).visible = true;
			}
		}
		
		private function checkIfWasRightClip():void
		{
			trace("cut the strip out");
			var scrub:Entity = getEntityById("scrubButton"+currentStrip);
			var controls:ScrollControl = ScrollControl(scrub.get(ScrollControl));
			var film:Entity = controls.centerEntity;
			var id:String = film.get(Id).id;
			
			Draw(shellApi.inputEntity.get(Draw)).penDown = false;
			returnRazor(getEntityById("razor"));
			
			if(id.substring(7) == "wrong")// wrong is supposed to indicate the odd one out not the wrong cut
			{
				reelsComplete[currentStrip] = true;
				
				// remove frame
				Display(film.get(Display)).visible = false;
				var feedBack:Entity = getEntityById("feedBack"+currentStrip);
				SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, Command.create(showFeedBack, feedBack)));
				
				// tween them together // move the 2 lower clips up
				
				var currentFrame:Entity = film;
				
				for(var i:int = 0; i < 2; i++)
				{
					var currentFrameNumber:int = controls.scrollingObjects.indexOf(currentFrame);
					var nextFrame:Entity = getNextFrame(currentFrameNumber, controls.scrollingObjects);
					trace(nextFrame.get(Id).id);
					if(nextFrame.get(Spatial).y < currentFrame.get(Spatial).y)
						break;
					var tween:Tween = new Tween();
					tween.to(nextFrame.get(Spatial), 1, {y:currentFrame.get(Spatial).y});
					nextFrame.add(tween);
					currentFrame = nextFrame;
				}
				
				// disable that film scrubber
				Slider(scrub.get(Slider)).enabled = false;
				
				findNextStrip();
			}
			else
			{
				setInstructions(labels[3]);//wrong frame
			}
		}
		
		private function showFeedBack(feedBack:Entity):void
		{
			Display(feedBack.get(Display)).visible = true;
			Timeline(feedBack.get(Timeline)).gotoAndPlay(0);
		}
		
		private function getNextFrame(currentFrame:int, frames:Vector.<Entity>):Entity
		{
			var nextFrameNumber:int = currentFrame + 1;
			
			trace(currentFrame + " " + nextFrameNumber + " " + frames.length);
			
			if(nextFrameNumber >= frames.length)
				nextFrameNumber = 0;
			var nextFrame:Entity = frames[nextFrameNumber];
			return nextFrame;
		}
		
		private function findNextStrip():void
		{
			score++;
			content.tfScore.text = score+"/3";
			var allDone:Boolean = true;
			for(var i:int = 0; i < reelsComplete.length; i++)
			{
				if(reelsComplete[i] == false)
				{
					currentStrip = i;
					allDone = false;
					cutZoneNumber = 0;
				}
			}
			if(allDone)
			{
				setInstructions(labels[4]);//game won
			}
		}
		
		private function setUpRazor():void
		{
			var razor:Entity = EntityUtils.createMovingEntity(this, content.razor, this.container);
			razor.add(new Id("razor"));
			razorInitPosition = new Point(razor.get(Spatial).x * content.scaleX, razor.get(Spatial).y * content.scaleY);
			TimelineUtils.convertClip(content.razor, this, razor, null, false);
			var time:Timeline = razor.get(Timeline);
			var interaction:Interaction = InteractionCreator.addToEntity(razor, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.OVER, InteractionCreator.OUT],content.razor);
			interaction.up.add(Command.create(mouseUpRazor, time));
			interaction.down.add(Command.create(mouseDownRazor, time));
			interaction.over.add(Command.create(mouseOverRazor, time));
			interaction.out.add(Command.create(mouseOutRazor, time));
			returnRazor(razor);
			
			var razorInstructions:Entity = EntityUtils.createSpatialEntity(this, content.razorInstructions, content);
			razorInstructions.add(new Id("razorInstructions"));
		}
		
		private function returnRazor(razor:Entity):void
		{
			var pos:Spatial = razor.get(Spatial);
			pos.x = razorInitPosition.x;
			pos.y = razorInitPosition.y;
			razor.remove(FollowTarget);
			holdingRazor = false;
			Draw(shellApi.inputEntity.get(Draw)).erase();
			resetCut();
		}
		
		private function mouseOutRazor(entity:Entity, timeline:Timeline):void
		{
			timeline.gotoAndStop("up");
		}
		
		private function mouseOverRazor(entity:Entity, timeline:Timeline):void
		{
			timeline.gotoAndStop("over");
		}
		
		private function mouseDownRazor(entity:Entity, timeline:Timeline):void
		{
			timeline.gotoAndStop("up");
			
			if(inMenu)
				return;
			
			if(!holdingRazor)
			{
				var follow:FollowTarget = new FollowTarget(shellApi.inputEntity.get(Spatial));
				follow.offset = new Point(0, 5);
				holdingRazor = true;
				entity.add(follow);
				
				setUpCuttingZone();
			}
			else
			{
				var pointerPos:Point = new Point(entity.get(Spatial).x, entity.get(Spatial).y);
				
				if(cuttingArea.contains(pointerPos.x, pointerPos.y))
				{
					trace("cut");
					Draw(shellApi.inputEntity.get(Draw)).penDown = true;
				}
				else
				{
					returnRazor(entity);
					trace("put razor back");
				}
			}
		}
		
		private function setUpCuttingZone():void
		{
			var cutZone:MovieClip = Display(getEntityById("cut_zone_"+currentStrip).get(Display)).displayObject as MovieClip;
			var zone:MovieClip = Display(getEntityById("cut_zone_"+cutZoneNumber+"_"+currentStrip).get(Display)).displayObject as MovieClip;
			Display(getEntityById("cut_zone_"+cutZoneNumber+"_"+currentStrip).get(Display)).visible = true;
			var strip:MovieClip = Display(getEntityById("strip"+currentStrip).get(Display)).displayObject as MovieClip;
			canvas = zone.zone;
			
			Draw(shellApi.inputEntity.get(Draw)).limits = canvas.getBounds(canvas);
			Draw(shellApi.inputEntity.get(Draw)).canvas = canvas;
			Draw(shellApi.inputEntity.get(Draw)).offset = new Point(strip.x + cutZone.x + zone.x + canvas.x, strip.y + cutZone.y + zone.y + canvas.y);
		}
		
		private function mouseUpRazor(entity:Entity, timeline:Timeline):void
		{
			timeline.gotoAndStop("over");
			Draw(shellApi.inputEntity.get(Draw)).penDown = false;
		}
		
		private function setUpInstructions():void
		{
			var dialogClip:MovieClip = content.dialog;
			var dialog:Entity = EntityUtils.createSpatialEntity(this, dialogClip, content);
			TimelineUtils.convertClip(dialogClip, this, dialog, null, false);
			dialog.add(new Id("instructions"));
			Display(dialog.get(Display)).visible = false;
			
			// can probably make this more efficient
			
			dialogClip.gotoAndStop(labels[0]);
			
			var title:Entity = EntityUtils.createSpatialEntity(this, dialogClip.title, content);
			title.add(new Id(labels[0]));
			
			var startBtn:Entity = EntityUtils.createSpatialEntity(this, dialogClip.title.btnStart, dialogClip.title);
			var interaction:Interaction = InteractionCreator.addToEntity(startBtn, [InteractionCreator.CLICK], dialogClip.title.btnStart);
			interaction.click.add(start);
			ToolTipCreator.addToEntity(startBtn);
			
			Display(title.get(Display)).visible = false;
			
			dialogClip.gotoAndStop(labels[2]);
			
			var badCut:Entity = EntityUtils.createSpatialEntity(this, dialogClip.mcGameLost, content);
			badCut.add(new Id(labels[2]));
			
			var okBtn:Entity = EntityUtils.createSpatialEntity(this, dialogClip.mcGameLost.btnOk, dialogClip.mcGameLost);
			interaction = InteractionCreator.addToEntity(okBtn, [InteractionCreator.CLICK], dialogClip.mcGameLost.btnOk);
			interaction.click.add(loose);
			ToolTipCreator.addToEntity(okBtn);
			
			Display(badCut.get(Display)).visible = false;
			
			dialogClip.gotoAndStop(labels[3]);
			
			var wrongFrame:Entity = EntityUtils.createSpatialEntity(this, dialogClip.mcGameLost, content);
			wrongFrame.add(new Id(labels[3]));
			
			okBtn = EntityUtils.createSpatialEntity(this, dialogClip.mcGameLost.btnOk, dialogClip.mcGameLost);
			interaction = InteractionCreator.addToEntity(okBtn, [InteractionCreator.CLICK], dialogClip.mcGameLost.btnOk);
			interaction.click.add(loose);
			ToolTipCreator.addToEntity(okBtn);
			
			Display(wrongFrame.get(Display)).visible = false;
			
			dialogClip.gotoAndStop(labels[4]);
			
			var gameWon:Entity = EntityUtils.createSpatialEntity(this, dialogClip.mcGameWon, content);
			gameWon.add(new Id(labels[4]));
			
			okBtn = EntityUtils.createSpatialEntity(this, dialogClip.mcGameWon.btnOk, dialogClip.mcGameWon);
			interaction = InteractionCreator.addToEntity(okBtn, [InteractionCreator.CLICK], dialogClip.mcGameWon.btnOk);
			interaction.click.add(gameWonOk);
			ToolTipCreator.addToEntity(okBtn);
			
			Display(gameWon.get(Display)).visible = false;
		}
		
		private function gameWonOk(entity:Entity):void
		{
			shellApi.triggerEvent(backlot.COMPLETE_EDITING, true);
			super.close();
		}
		
		private function loose(entity:Entity):void
		{
			resetClips();
			startGame();
		}
		
		private function start(entity:Entity):void
		{
			play();
		}
		
		private function play():void
		{
			startVisualHints();
			setScrolling(0);
			setInstructions(labels[1]);//play
			inMenu = false;
		}
		
		private var scrubNumber:int;
		
		private function startVisualHints():void
		{
			scrubNumber = 0;
			SceneUtil.addTimedEvent(this, new TimedEvent(3,1,Command.create(showRazorControls)));
			SceneUtil.addTimedEvent(this, new TimedEvent(.75,3,Command.create(highLightScrubs)));
		}
		
		private function highLightScrubs():void
		{
			var scrub:Entity = getEntityById("scrubberHilite"+scrubNumber);
			Display(scrub.get(Display)).moveToFront();
			var tween:Tween = new Tween();
			tween.to(scrub.get(Display), .5, {alpha:1, onComplete:hideHighLight});
			scrub.add(tween);
		}
		
		private function hideHighLight():void
		{
			var scrub:Entity = getEntityById("scrubberHilite"+scrubNumber);
			var tween:Tween = new Tween();
			tween.to(scrub.get(Display), .5, {alpha:0, onComplete:Command.create(moveToBack, scrub)});
			scrub.add(tween);
			scrubNumber++;
		}
		
		private function moveToBack(entity:Entity):void
		{
			Display(entity.get(Display)).moveToBack();
		}
		
		private function showRazorControls():void
		{
			var razorInstructions:Entity = getEntityById("razorInstructions");
			var tween:Tween = new Tween();
			tween.to(razorInstructions.get(Display) ,3, {alpha:1});
			razorInstructions.add(tween);
		}
		
		private function setUpStrips():void
		{
			for(var i:int = 0; i < 3; i ++)
			{
				//setting up the film reels
				var clipName:String = "film_clip_"+i+".swf";
				var strip:MovieClip = content["strip"+i];
				
				var stripEnt:Entity = EntityUtils.createSpatialEntity(this, strip, content);
				stripEnt.add(new Id("strip"+i));
				var cover:Entity = EntityUtils.createDisplayEntity(this, strip.filmDisplay, strip.frameContainer);
				
				// setting up scrubber (to roll though film)
				
				// visual effect for trying to show players what they should do to interact with the game
				var scrubberHilite:Entity = EntityUtils.createSpatialEntity(this, strip.scrubberHilite, strip);
				scrubberHilite.add(new Id("scrubberHilite"+i));
				Display(scrubberHilite.get(Display)).alpha = 0;
				
				// the actual scrubber
				var scrubButton:Entity = EntityUtils.createSpatialEntity(this, strip.btn, strip);
				TimelineUtils.convertClip(strip.btn, this, scrubButton, null, false);
				var time:Timeline = scrubButton.get(Timeline);
				scrubButton.add(new Id("scrubButton"+i));
				
				// setting up all the interactions for the scrubber
				var interaction:Interaction = InteractionCreator.addToEntity(scrubButton, [InteractionCreator.OVER, InteractionCreator.OUT, InteractionCreator.DOWN,InteractionCreator.UP],strip.btn);
				interaction.over.add(Command.create(mouseOverScrub, time));
				interaction.up.add(Command.create(mouseUpScrub, time));
				interaction.down.add(Command.create(mouseDownScrub, time));
				interaction.out.add(Command.create(mouseOutScrub, time));
				
				// setting up the systems for using the scrubber
				var slider:Slider = new Slider();
				slider.dragger = shellApi.inputEntity.get(Spatial);
				slider.maxDistance = 50;
				slider.origin = new Point(strip.btn.x, strip.btn.y);
				slider.offset = new Point(strip.x, strip.y);
				slider.scale = new Point(content.scaleX, content.scaleY);
				scrubButton.add(slider);
				scrubButton.add(new ScrollControl(null, 25, true));// the true for swapXandY is because the slider moves side to side while the film moves up and down
				
				//setting up the editing instructions 
				var cutZones:MovieClip = strip.cutZones;
				var cutZone:Entity = EntityUtils.createSpatialEntity(this, cutZones, strip);
				cutZone.add(new Id("cut_zone_"+i));
				
				for(var z:int = 0; z < 2; z++)
				{
					var zone:Entity = EntityUtils.createSpatialEntity(this, cutZones["zone"+z], cutZones);
					zone.add(new Id("cut_zone_"+z+"_"+i));
					Display(zone.get(Display)).visible = false;
				}
				
				//setting up feedback
				var editFeedBack:Entity = EntityUtils.createSpatialEntity(this, strip.mcEditComplete, strip);
				editFeedBack.add(new Id("feedBack"+i));
				TimelineUtils.convertClip(strip.mcEditComplete, this, editFeedBack, null, false);
				Display(editFeedBack.get(Display)).visible = false;
				Timeline(editFeedBack.get(Timeline)).labelReached.add(Command.create(stopAtCheckMark, 	editFeedBack.get(Timeline)));			
				// for choosing which clip to set to being the odd one out
				var wrong:int = (int)(Math.random() * clipsPerStrip);
				
				for(var c:int = 0; c < clipsPerStrip; c++)// for the number of clips
				{
					loadFile(clipName, onClipLoaded, scrubButton, strip.frameContainer, c, wrong);
				}
			}
		}
		
		private function stopAtCheckMark(label:String, timeline:Timeline):void
		{
			if(label == "ending")
				timeline.gotoAndStop(timeline.currentIndex);
		}
		
		private function mouseOutScrub(entity:Entity, timeline:Timeline):void
		{
			if(!Slider(entity.get(Slider)).enabled)
				return;
			
			timeline.gotoAndStop("out");
		}
		
		private function mouseDownScrub(entity:Entity, timeline:Timeline):void
		{
			if(!Slider(entity.get(Slider)).enabled)
				return;
			
			var id:String = entity.get(Id).id;
			currentStrip = parseInt(id.charAt(id.length - 1));// will be either 0, 1, or 2
			
			timeline.gotoAndStop("down");
			Slider(entity.get(Slider)).drag = true;
			ScrollControl(entity.get(ScrollControl)).scrolling = true;
		}
		
		private function mouseUpScrub(entity:Entity, timeline:Timeline):void
		{
			if(!Slider(entity.get(Slider)).enabled)
				return;
			
			timeline.gotoAndStop("over");
			Slider(entity.get(Slider)).drag = false;
			ScrollControl(entity.get(ScrollControl)).centerizeScrollingObjects();
		}
		
		private function mouseOverScrub(entity:Entity, timeline:Timeline):void
		{
			if(!Slider(entity.get(Slider)).enabled)
				return;
			
			timeline.gotoAndStop("over");
		}
		
		private function onClipLoaded(clip:DisplayObjectContainer, scrubButton:Entity, stripContainer:MovieClip, stripNumber:int, wrongClipNumber:int):void
		{
			var mc:MovieClip = clip as MovieClip;
			
			var clipEnt:Entity = EntityUtils.createSpatialEntity(this, clip, stripContainer);
			TimelineUtils.convertClip(mc, this,clipEnt, null, false);
			
			if(stripNumber == wrongClipNumber)
			{
				clipEnt.add(new Id("film_" + stripNumber + "_wrong"));
				mc.film.gotoAndStop(1);//wrong
			}
			else
			{
				clipEnt.add(new Id("film_" + stripNumber + "_right"));
				mc.film.gotoAndStop(2);//right
			}
			
			Spatial(clipEnt.get(Spatial)).y = clip.height * stripNumber - clip.height / 2;
			clipEnt.add(new Scroll(null, new Rectangle(stripContainer.x - clip.width / 2, stripContainer.y, clip.width, clip.height * (clipsPerStrip - 1))));
			
			ScrollControl( scrubButton.get(ScrollControl)).scrollingObjects.push(clipEnt);
			clipsLoaded++;
			trace(clipsLoaded);
			if(clipsLoaded == clipsPerStrip * 3)
			{
				resetClips();
				startGame();
			}
		}
		
		private function resetCut():void
		{
			for(var i:int = 0; i < 3; i++)
			{
				Display(getEntityById("cut_zone_0_"+i).get(Display)).visible = false;
				Display(getEntityById("cut_zone_1_"+i).get(Display)).visible = false;
			}
			cutZoneNumber = 0;
		}
		
		private function resetClips():void
		{
			for(var i:int = 0; i < 3; i++)
			{
				reelsComplete[i] = false;
				var scrub:Entity = getEntityById("scrubButton"+i);
				Display(getEntityById("cut_zone_"+i).get(Display)).moveToFront();
				Display(getEntityById("cut_zone_0_"+i).get(Display)).visible = false;
				Display(getEntityById("cut_zone_1_"+i).get(Display)).visible = false;
				Display(getEntityById("feedBack"+i).get(Display)).visible = false;
				var scrubControls:ScrollControl = scrub.get(ScrollControl);
				Slider(scrub.get(Slider)).enabled = true;
				var orderedList:Vector.<Entity> = new Vector.<Entity>(scrubControls.scrollingObjects.length);
				for(var c:int = 0; c < scrubControls.scrollingObjects.length;c++)
				{
					var clipEnt:Entity = scrubControls.scrollingObjects[c];
					trace(Id(clipEnt.get(Id)).id);
					var properOrder:int = parseInt( Id(clipEnt.get(Id)).id.substr(5,1));
					orderedList[properOrder] = clipEnt;
					var clip:DisplayObject = Display(clipEnt.get(Display)).displayObject;
					clipEnt.get(Spatial).y = clip.height * properOrder - clip.height / 2;
					Display(clipEnt.get(Display)).visible = true;
				}
				scrubControls.scrollingObjects = orderedList;
			}
		}
		
		private function startGame():void
		{
			score = 0;
			content.tfScore.text = "0/3";
			Display(getEntityById("razorInstructions").get(Display)).alpha = 0;
			setScrolling(2);
			setInstructions(labels[0]);//init
		}
		
		private function setInstructions(label:String):void
		{
			for(var i:int = 0; i < labels.length; i++)
			{
				if(labels[i] != "play")
				{
					Display(getEntityById(labels[i]).get(Display)).visible = false;
				}
			}
			if(label != "play")
			{
				Display(getEntityById(label).get(Display)).visible = true;
				inMenu = true;
			}
		}
		
		public function setScrolling(scrollSpeedMultiplier:Number):void
		{
			for(var i:int = 0; i < 3; i++)
			{
				var scrub:Entity = getEntityById("scrubButton"+i);
				
				var slider:Slider = scrub.get(Slider);
				var speed:Number = Math.random() * scrollSpeedMultiplier - scrollSpeedMultiplier / 2;
				slider.value = new Point(speed, 0);
				
				var scrubControls:ScrollControl = scrub.get(ScrollControl);
				
				if(scrollSpeedMultiplier == 0)
					scrubControls.centerizeScrollingObjects();
				else
					scrubControls.scrolling = true;
			}
		}
		
		override public function close( removeOnClose:Boolean = true, onCloseHandler:Function = null ):void
		{
			super.close();
		}
	}
}