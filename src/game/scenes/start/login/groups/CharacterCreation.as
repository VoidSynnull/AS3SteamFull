package game.scenes.start.login.groups
{
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Rectangle;
	import flash.net.URLVariables;
	import flash.text.TextField;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.MotionBounds;
	import engine.creators.InteractionCreator;
	import engine.group.DisplayGroup;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.motion.Draggable;
	import game.components.motion.Edge;
	import game.components.timeline.Timeline;
	import game.components.ui.Button;
	import game.components.ui.Ratio;
	import game.components.ui.Slider;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.animation.entity.character.DanceMoves01;
	import game.data.animation.entity.character.Guitar;
	import game.data.animation.entity.character.Laugh;
	import game.data.animation.entity.character.Pop;
	import game.data.animation.entity.character.Proud;
	import game.data.animation.entity.character.Wave;
	import game.data.character.LookData;
	import game.data.sound.SoundModifier;
	import game.scenes.start.login.Login;
	import game.scenes.start.login.data.CharLookLibrary;
	import game.systems.motion.BoundsCheckSystem;
	import game.systems.motion.DraggableSystem;
	import game.systems.ui.SliderSystem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.ColorUtil;
	import game.util.DataUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TextUtils;
	import game.util.Utils;
	
	import org.osflash.signals.Signal;
	
	public class CharacterCreation extends DisplayGroup
	{
		private var display:DisplayObjectContainer;
		
		private var dummy:Entity;
		
		private var slider:Entity;
		private var ratio:Ratio;
		private var edge:Edge;
		
		private var tabTemplate:MovieClip;
		private var tabContent:MovieClip;
		private var buttonBG:MovieClip;
		private var buttonContent:MovieClip;
		private var buttonTemplate:MovieClip;
		
		private var title:TextField;
		private var contentContainer:MovieClip;
		private var tabContainer:MovieClip;
		
		private var assetsToLoad:int;
		
		private var library:CharLookLibrary;
		
		private const IGNORED_KEYS:Array = [SkinUtils.GENDER];
		private const PART_PREFIX:String = "entity/character/";
		private const COLOR_KEYS:Array = [SkinUtils.HAIR_COLOR, SkinUtils.SKIN_COLOR];
		private var TABS:Array = [SkinUtils.HAIR_COLOR, SkinUtils.SKIN_COLOR, SkinUtils.HAIR, SkinUtils.MOUTH, SkinUtils.SHIRT, SkinUtils.PANTS, SkinUtils.EYE_STATE];
		private var tabNames:Dictionary;
		
		private var loadedParts:Dictionary;
		
		private var currentTab:String;
		private var buttons:Array;
		
		private const COLUMNS:int = 8;
		private const SPACING:Number = 15;
		private const NO_SCROLL:Number = 18.5;
		private const TAB_WIDTH:Number = 80;
		private const BUTTON_SIZE:Number = 51;
		private const CONTENT_SIZE:Number = 42;
		
		private var animComplete:Boolean = true;
		private var animations:Array = [DanceMoves01, Guitar, Laugh, Proud, Wave];
		
		// set up edge cases for parts that share an asset with a different name than the part
		private var edgeCases:Dictionary;
		
		public var libraryReady:Signal;
		private var firstTime:Boolean = true;
		
		override public function destroy():void
		{
			if(libraryReady != null)
			{
				libraryReady.removeAll();
				libraryReady = null;
			}
			tabNames = null;
			edgeCases = null;
			buttons = null;
			loadedParts = null;
			library = null;
			display = null;
			tabContainer = null;
			tabContent = null;
			tabTemplate = null;
			buttonBG = null;
			buttonContent = null;
			buttonTemplate = null;
			title = null;
			contentContainer = null;
			super.destroy();
		}
		
		public function CharacterCreation(container:DisplayObjectContainer=null, library:CharLookLibrary = null, dummy:Entity = null)
		{
			libraryReady = new Signal();
			this.dummy = dummy;
			loadedParts = new Dictionary();
			edgeCases = new Dictionary();
			tabNames = new Dictionary();
			this.library = library;
			display = container;
			super(display.parent);
			this.id = "CharacterCreation";
			this.groupPrefix = "scenes/start/login/selections/";
			setUpEdgeCases();
		}
		
		private function setUpEdgeCases():void
		{
			edgeCases["ppunkguy1"] = "ppunkguy";
			edgeCases["ppunkguy2"] = "ppunkguy";
			edgeCases["ppunkguy3"] = "ppunkguy";
			edgeCases["ppunkguy4"] = "ppunkguy";
			edgeCases["ppunkguy5"] = "ppunkguy";
			edgeCases["ppunkgirl1"] = "ppunkgirl";
			edgeCases["ppunkgirl2"] = "ppunkgirl";
			edgeCases["ppunkgirl3"] = "ppunkgirl";
			edgeCases["ppunkgirl4"] = "ppunkgirl";
			edgeCases["ppunkgirl5"] = "ppunkgirl";
			
			tabNames[SkinUtils.SKIN_COLOR] = "SKIN COLOR";
			tabNames[SkinUtils.HAIR_COLOR] = "HAIR COLOR";
			tabNames[SkinUtils.HAIR] = "HAIR";
			tabNames[SkinUtils.MOUTH] = "MOUTH";
			tabNames[SkinUtils.SHIRT] = "TOP";
			tabNames[SkinUtils.PANTS] = "BOTTOM";
			tabNames[SkinUtils.EYE_STATE] = "EYES";
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			super.init(container);
			if(library)
				loadLibrary(true);
			else
				loadFiles([groupPrefix+"displayButton.swf", groupPrefix+"tab.swf"],true,true, loaded);
		}
		
		public function ChangeLibraries(library:CharLookLibrary):void
		{
			if(library != this.library)
			{
				currentTab = null;
				this.library = library;
				loadLibrary();
			}
			else
			{
				libraryReady.dispatch();
			}
		}
		
		private function loadLibrary(firstTime:Boolean = false):void
		{
			var assets:Array;
			if(firstTime)
				assets = [groupPrefix+"displayButton.swf", groupPrefix+"tab.swf"];
			else
				assets = [];
			
			var url:String;
			var partPrefix:String;
			// TODO Auto Generated method stub
			for(var key:String in library.Parts)
			{
				if(IGNORED_KEYS.indexOf(key) >=0)
					continue;
				
				url = groupPrefix+key+".swf";
				if(!loadedParts.hasOwnProperty(url) && assets.indexOf(url) == -1)
					assets.push(url);
				/*
				if(COLOR_KEYS.indexOf(key) >= 0)
				continue;
				
				partPrefix = PART_PREFIX+key+"/";
				if(key == SkinUtils.EYE_STATE)
				partPrefix = groupPrefix;//eye state has custom assets
				
				var parts:Array = library.Parts[key];
				for(var i:int = 0; i < parts.length; i++)
				{
				var part:String = parts[i];
				part = part.toLowerCase();
				if(edgeCases.hasOwnProperty(part))
				part = edgeCases[part];
				url = partPrefix+part+".swf";
				if(!loadedParts.hasOwnProperty(url) && assets.indexOf(url) == -1)
				assets.push(url);
				}
				*/
			}
			
			if(firstTime)
				loadFiles(assets,true,true,loaded);
			else
				loadFiles(assets,true,true,updateLibrary);
		}
		
		override public function loaded():void
		{
			addSystem(new DraggableSystem());
			addSystem(new SliderSystem());
			addSystem(new BoundsCheckSystem());
			tabTemplate = getAsset(groupPrefix+"tab.swf",true,true).getChildAt(0);
			tabContent = tabTemplate["container"];
			buttonTemplate = getAsset(groupPrefix+"displayButton.swf",true,true).getChildAt(0);
			buttonContent = buttonTemplate["button"]["content"];
			buttonContent.mouseChildren = buttonContent.mouseEnabled = false;
			buttonContent.mask = buttonTemplate["button"]["mask"];
			buttonBG = buttonTemplate["button"]["bg"];
			contentContainer = display["DisplayContainer"];
			contentContainer.mask = display["DisplayMask"];
			tabContainer = display["tabContainer"];
			title = TextUtils.refreshText(display["title"]);
			updateLibrary();
			setupSlider();
			super.loaded();
		}
		
		private function setupSlider():void
		{
			var container:MovieClip = display["sliderContainer"];
			
			slider = EntityUtils.createSpatialEntity(this, container.slider);
			InteractionCreator.addToEntity(slider, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.RELEASE_OUT]);
			var draggable:Draggable = new Draggable("y");
			draggable.dragging.add(UpdateSlider);
			slider.add(draggable);
			slider.add(new Slider());
			slider.add(new MotionBounds(container.getBounds(container)));
			var rect:Rectangle = container.slider.getBounds(container.slider);
			edge = new Edge(rect.x, rect.y, rect.width, rect.height);
			slider.add(edge);
			ratio = new Ratio();
			slider.add(ratio);
			ToolTipCreator.addToEntity(slider);
			
			var bar:Entity = EntityUtils.createSpatialEntity(this, container.bar);
			var interaction:Interaction = InteractionCreator.addToEntity(bar, [InteractionCreator.CLICK]);
			interaction.click.add(this.onBarClicked);
			ToolTipCreator.addToEntity(bar);
		}
		
		private function UpdateSlider(entity:Entity):void
		{
			var scale:Number = Math.max(0,contentContainer.height + SPACING - contentContainer.mask.height);
			contentContainer.y = -206 - ratio.decimal * scale;
			//trace(contentContainer.y + " " + scale + " " + ratio.decimal);
		}
		
		private function onBarClicked(bar:Entity):void
		{
			var display:DisplayObject = bar.get(Display).displayObject;
			var box:Rectangle = slider.get(MotionBounds).box;
			
			ratio.decimal = Utils.toDecimal(display.mouseY, box.top, box.bottom);
			UpdateSlider(slider);
		}
		
		private function updateLibrary():void
		{
			if(library == null)
				return;
			
			var entity:Entity;
			var image:DisplayObject;
			var url:String;
			
			// TODO Auto Generated method stub
			for(var i:int = 0; i < TABS.length; i++)
			{
				var key:String = TABS[i];
				if(IGNORED_KEYS.indexOf(key) >=0)
					continue;
				
				entity = getEntityById(key);
				if(entity == null)
				{
					url = groupPrefix+key+".swf";
					if(loadedParts.hasOwnProperty(url))
						image = loadedParts[url];
					else
					{
						image = getAsset(url,true,true);
						image = MovieClip(image).getChildAt(0);
						loadedParts[url] = image;
					}
					tabContent.addChild(image);
					tabTemplate.x = i * TAB_WIDTH;
					entity = ButtonCreator.createButtonEntity(tabTemplate, this, changeTab, tabContainer, null, null, true,true,2);
					var interaction:Interaction = entity.get(Interaction);
					interaction.over.add(onHover);
					tabContent.removeChild(image);
					entity.add(new Id(key));
				}
			}
			setUpTab(TABS[0]);
			libraryReady.dispatch();
			firstTime = false;
		}
		
		private function setUpTab(key:String):void
		{
			if(currentTab == key)
				return;
			
			ratio.decimal = 0;
			UpdateSlider(slider);
			
			playAvatarAnimations(animations);
			
			var button:Entity;
			// reset tabs
			for(var btn:String in library.Parts)
			{
				if(IGNORED_KEYS.indexOf(btn) >=0)
					continue;
				
				button = getEntityById(btn);
				Button(button.get(Button)).isSelected = false;
			}
			button = getEntityById(key);
			Button(button.get(Button)).isSelected = true;
			
			currentTab = key;
			title.text = tabNames[key];
			
			if(!firstTime)
				customizeTrackingCall("NewUserTabClicked", getTrackingTabName(key));
			else
				customizeTrackingCall("NewUserStartTab", getTrackingTabName(key));
			
			var isColorKey:Boolean = COLOR_KEYS.indexOf(key) >= 0;
			var url:String;
			var parts:Array = library.Parts[key];
			
			EntityUtils.getDisplayObject(slider).parent.visible = parts.length/3>COLUMNS;
			
			var image:DisplayObjectContainer;
			if(buttons != null)
			{
				for each(button in buttons)
				{
					removeEntity(button);
				}
			}
			buttons = [];
			
			var col:int = 0;
			var row:int = 0;
			
			var hairColor:Number = -1;
			if(key == SkinUtils.HAIR)
			{
				hairColor = SkinUtils.getLook(dummy).getValue(SkinUtils.HAIR_COLOR);
			}
			
			assetsToLoad = 0;
			
			for(var i:int = 0; i < parts.length; i++)
			{
				if(isColorKey)
				{
					setUpButton(null, key, parts[i], col, row, isColorKey, hairColor);
				}
				else
				{
					var part:String = parts[i];
					part = part.toLowerCase();
					if(edgeCases.hasOwnProperty(part))
						part = edgeCases[part];
					
					url = PART_PREFIX+key+"/"+part+".swf";
					if(key == SkinUtils.EYE_STATE)
					{
						url = groupPrefix+part+".swf";
					}
					if(loadedParts.hasOwnProperty(url))
					{
						image = loadedParts[url];
						setUpButton(image, key, parts[i], col, row, isColorKey, hairColor);
					}
					else
					{
						if(assetsToLoad == 0)// dont let player swap tabs while current tab is still loading
							SceneUtil.lockInput(this);
						assetsToLoad++;
						shellApi.loadFile(shellApi.assetPrefix+url, Command.create(setUpButton, key, parts[i], col, row, isColorKey, hairColor, url));
					}
				}
				
				col++;
				if(col >= COLUMNS)
				{
					col = 0;
					row++;
				}
			}
			//EntityUtils.visible(slider, row>=3);
			
		}
		
		private function setUpButton(image:DisplayObjectContainer, key:String, val:String, col:int, row:int, isColorKey:Boolean, hairColor:Number = -1, url:String = ""):void
		{
			if(DataUtils.validString(url))
			{
				loadedParts[url] = image;
				var scale:Number = (image.width == 0 || image.height == 0)?1:Math.min(CONTENT_SIZE / image.width, CONTENT_SIZE/image.height);
				image.scaleX = image.scaleY = scale;
				image.scaleX *= -1;
				image.x = image.y = 0;
				buttonContent.addChild(image);
				var rect:Rectangle = image.getRect(buttonContent);
				image.x = -(rect.left + rect.width / 2);
				image.y = -(rect.top + rect.height / 2);
				var activeObject:MovieClip = image["active_obj"];
				if(activeObject)// stop active object timelines from running
				{
					activeObject.gotoAndStop(1);
				}
				assetsToLoad--;
				if(assetsToLoad == 0)
					SceneUtil.lockInput(this, false);
			}
			else if(!isColorKey)
				buttonContent.addChild(image);
			
			if(hairColor > -1)
				ColorUtil.colorize(image, hairColor);
			
			if(isColorKey)
				ColorUtil.colorize(buttonBG, Number(val));
			else
				ColorUtil.colorize(buttonBG, 0xFFFFFF);
			
			var parts:Array = library.Parts[key];
			
			var spacingX:Number = (parts.length/3<=COLUMNS)?NO_SCROLL:SPACING;
			
			buttonTemplate.x = BUTTON_SIZE / 2 + spacingX + (BUTTON_SIZE + spacingX) * col;
			buttonTemplate.y = BUTTON_SIZE / 2 + SPACING + (BUTTON_SIZE + SPACING) * row;
			var entity:Entity = ButtonCreator.createButtonEntity(buttonTemplate, this, Command.create(updateDummy, key, val),contentContainer,null,null,true,true);
			smoothBitmapping(entity);
			var interaction:Interaction = entity.get(Interaction);
			interaction.over.add(onHover);
			buttons.push(entity);
			
			if(!isColorKey)
				buttonContent.removeChild(image);
			
			
		}
		
		private function onHover(button:Entity):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "ui_roll_over.mp3", 1, false, SoundModifier.EFFECTS);
		}
		
		private function smoothBitmapping(button:Entity):void
		{
			var disp:DisplayObjectContainer = EntityUtils.getDisplayObject(button);
			var bitmap:Bitmap = disp.getChildAt(0) as Bitmap;
			bitmap.smoothing = true;
		}
		
		private function updateDummy(button:Entity, key:String, value:String):void
		{
			trace("key: " + key + " value: " + value);
			if(dummy == null)
				return;
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "ui_button_click.mp3", 1, false, SoundModifier.EFFECTS);
			
			customizeTrackingCall("NewUser"+getTrackingTabName(key)+"Selected", value);
			
			var look:LookData = SkinUtils.getLook(dummy);
			
			if(key == SkinUtils.EYE_STATE)// we are now combining gender and eye state
			{
				if(value.indexOf("_"))
				{
					var values:Array = value.split("_");
					look.setValue(key, values[0]);
					look.setValue(SkinUtils.GENDER, values[1]);
					SkinUtils.setEyeStates(dummy, values[0]);
				}
				else
				{
					look.setValue(key, value);
					SkinUtils.setEyeStates(dummy, value);// old
				}
			}
			else
			{
				look.setValue(key, value);
			}
			
			SkinUtils.applyLook(dummy, look);
			
			playAvatarAnimations([Pop]);
		}
		
		private function changeTab(button:Entity):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "ui_button_click.mp3", 1, false, SoundModifier.EFFECTS);
			var id:String = button.get(Id).id;
			setUpTab(id);
		}
		
		private function playAvatarAnimations(array:Array):void
		{
			if(animComplete)
			{
				animComplete = false;
				var anim:Class = array[int(array.length * Math.random())];
				trace(anim);
				CharUtils.setAnim(dummy, anim);
				Timeline(dummy.get(Timeline)).handleLabel("ending", onCompletedAnimation);
			}
		}
		
		private function onCompletedAnimation():void
		{
			animComplete = true;
		}
		
		private function getTrackingTabName(tab:String):String
		{
			var tabTitle:String = tabNames[tab];
			var nameParts:Array = tabTitle.split(" ");
			var trackingValue:String = "";
			for(var nameIndex:int = 0; nameIndex < nameParts.length; nameIndex++)
			{
				var namePart:String = nameParts[nameIndex];
				trackingValue += namePart.substr(0,1).toUpperCase() + namePart.substr(1).toLowerCase();
			}
			return trackingValue;
		}
		
		private function customizeTrackingCall(event:String, choice:String = null, subChoice:String = null):void
		{
			Login(parent).customizeTracking(event, choice, subChoice);
		}
	}
}