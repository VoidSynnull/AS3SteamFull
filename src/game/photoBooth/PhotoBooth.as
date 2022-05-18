package game.photoBooth
{
	import com.adobe.images.PNGEncoder;
	import com.poptropica.AppConfig;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.FileReference;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.system.Security;
	import flash.system.SecurityPanel;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.TransformTool;
	import game.components.entity.Children;
	import game.components.entity.Sleep;
	import game.components.entity.character.Skin;
	import game.components.motion.Draggable;
	import game.components.motion.Edge;
	import game.components.motion.FollowTarget;
	import game.components.motion.TargetSpatial;
	import game.components.motion.Threshold;
	import game.components.timeline.BitmapTimeline;
	import game.components.ui.Book;
	import game.components.ui.Button;
	import game.components.ui.Ratio;
	import game.components.ui.Slider;
	import game.creators.ui.ButtonCreator;
	import game.data.photobooth.DialogBoxData;
	import game.data.photobooth.PhotoBoothData;
	import game.data.photobooth.PhotoBoothSceneData;
	import game.data.photobooth.StickerAssetData;
	import game.data.photobooth.StickerData;
	import game.data.photobooth.StickerSheet;
	import game.data.photobooth.StickerTextData;
	import game.data.TimedEvent;
	import game.data.character.LookAspectData;
	import game.data.character.LookData;
	import game.data.display.BitmapWrapper;
	import game.data.display.SpatialData;
	import game.data.profile.ProfileData;
	import game.managers.interfaces.IAdManager;
	import game.proxy.DataStoreRequest;
	import game.scene.template.CharacterGroup;
	import game.scene.template.ItemGroup;
	import game.scene.template.ui.CardGroup;
	import game.systems.TransformToolSystem;
	import game.systems.motion.BoundsCheckSystem;
	import game.systems.motion.DraggableSystem;
	import game.systems.motion.ThresholdSystem;
	import game.systems.ui.BookSystem;
	import game.systems.ui.SliderSystem;
	import game.ui.elements.ConfirmationDialogBox;
	import game.ui.photo.CharacterPoseData;
	import game.ui.popup.Popup;
	import game.ui.screenCapture.CaptionData;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DataUtils;
	import game.util.DisplayPositions;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.GridAlignment;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TextUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	public class PhotoBooth extends Popup
	{
		private var campaign:String = "PhotoBooth"
		
		private const DEV_QUALITY:Number = .25;
		
		private var stickers:Vector.<Entity>;
		
		private var dataPath:String;
		
		private var charGroup:CharacterGroup;
		
		private var itemGroup:ItemGroup;
		
		private var boothData:PhotoBoothData;
		
		private var dummy:Entity;
		
		private var content:MovieClip;
		
		private var bg:Entity;
		
		private var toolTab:Entity;
		
		private var stickerTab:Entity;
		
		private var currentSticker:Entity;
		
		private var scene:MovieClip;
		private var border:MovieClip;
		
		private var header:MovieClip;
		private var promo:MovieClip;
		
		private var tabNumber:int;
		private var subTabNumber:int;
		
		private var indexNumbers:Dictionary;
		
		private var transformTool:Entity;
		
		private var follow:FollowTarget;
		
		private var showingTab:Boolean;
		
		private var nameDisplay:TextField;
		
		private var origin:Point;
		private var prefabContainer:DisplayObjectContainer;
		
		private const TEMP:String	= "tempSaves";
		
		private const TOOLS:Array = [ALPHA,LAYER];
		
		private const ALPHA:String = "alphaSlider";
		private const LAYER:String = "layerSlider";
		
		private const TABS:Array = [NPCS,BGS,STICKERS,TEXT_FIELDS,TEMPLATES];//
		private const NPCS_SUB_TABS:Array = [EXPRESSIONS,ITEMS,POSES];
		private const TEXT_FIELDS_SUB_TABS:Array = [FONTS, COLORS, SIZES];
		//tabs
		private const BGS:String = "bgs";
		private const STICKERS:String = "stickers";
		private const NPCS:String = "npcs";
		private const TEMPLATES:String = "templates";
		private const TEXT_FIELDS:String = "textFields";
		
		//npc sub tabs
		private const EXPRESSIONS:String = "expressions";
		private const ITEMS:String = "items";
		private const POSES:String = "poses";
		
		private const FONTS:String	= "fonts";
		private const COLORS:String	= "colors";
		private const SIZES:String	= "sizes";
		
		private const TAB:String	= "Tab";
		
		//sounds
		private const OPEN_TAB:String = "air_pump_release_01.mp3";
		private const CLOSE_TAB:String = "air_pump_intake_01.mp3";
		
		private const CLICK_EXIT:String = "ui_close_cancel.mp3";
		private const CLICK_SAVE:String = "photo_shoot_01.mp3";
		
		private const DRAG_STICKER:String = "majong_single_flip_01.mp3";
		private const DROP_STICKER:String = "majong_swap_01.mp3";
		
		private const SELECT_BG:String = "map_scroll.mp3";
		private const SELECT_TEMPLATE:String = "fart_04.mp3";//not sure what to for this one
		private const DELETE_SCENE:String = "metal_crash_impact_01.mp3";
		private const DELETE_STICKER:String = "metal_crash_impact_01.mp3";
		
		private const SCROLL_OPTIONS:String	= "bead_curtain_01.mp3";
		
		public var stickerLimit:uint = 50;
		
		private var currentLayout:PhotoBoothSceneData;
		
		private var dragging:Boolean = false;
		
		private var tempsSaved:int = 0;
		private const TEMPS_PER_PAGE:int = 3;
		
		private var input:TextField;
		
		private var photoNumber:Number = 0;
		
		private var unique:Boolean;
		
		private var picData:BitmapData;
		
		private var optimize:Boolean;
		
		private var slidingTab:Boolean = false;
		
		private var cardType:String = CardGroup.CUSTOM; //"limited";
		
		private var fileName:String;
		
		public function PhotoBooth(container:DisplayObjectContainer, dataPath:String, campaign:String = null)
		{
			super(container);
			screenAsset = "photo_booth_popup.swf";
			groupPrefix = "photoBooth/";
			configData(dataPath, campaign);
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			super.init(container);
			if(data != null)
			{
				configData(data.path, data.campaign);
			}
			load();
		}
		
		public function configData(dataPath:String, campaign:String = null):void
		{
			this.dataPath = dataPath;
			if(campaign != null)
				this.campaign = campaign;
			else
			{
				var prefix:String = "data/limited/";
				var suffix:String = "/photobooth.xml"
				this.campaign = dataPath.substring(prefix.length, dataPath.length - suffix.length);
			}
		}
		
		override public function load():void
		{
			shellApi.loadFile(dataPath, setUpData);
		}
		
		override public function destroy():void
		{
			clearPhoto();
			dummy = null;
			content = null;
			bg = null;
			stickerTab = null;
			scene = null;
			border = null;
			currentSticker = null;
			header = null;
			indexNumbers = null;
			transformTool = null;
			input = null;
			if(picData != null)
			{
				picData.dispose();
				picData = null;
			}
			super.destroy();
		}
		
		private function setUpData(xml:XML):void
		{
			boothData = new PhotoBoothData(xml, shellApi);
			
			var prelimAssets:Array = boothData.poses.concat(groupPrefix+screenAsset);
			
			if(boothData.theme != null && isNaN(boothData.theme))
				prelimAssets.push(boothData.theme);
			
			if(boothData.headerData != null)
				prelimAssets.push(boothData.headerData.asset);
			
			if(boothData.promo != null)
				prelimAssets.push(boothData.promo.asset);
			
			//only load in what is necesary 
			loadFiles(prelimAssets,true, true, assetsLoaded);
		}
		
		private function assetsLoaded():void
		{
			super.screen = super.getAsset(super.screenAsset, true) as MovieClip;
			content = screen.content;
			charGroup = new CharacterGroup();
			charGroup.id = "photoCharGroup";
			charGroup.setupGroup(this, content.tab.npcsTab.container);
			charGroup.createDummy("player",boothData.npcs[0].stickers[0].look,"right","",null,null,dummyLoaded,true, .55);
			boothData.setUpPrelimAssets(this);
		}
		
		private function dummyLoaded(entity):void
		{
			addSystem(new DraggableSystem());
			addSystem(new SliderSystem());
			addSystem(new TransformToolSystem());
			addSystem(new BookSystem());
			addSystem(new ThresholdSystem());
			
			optimize = PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGHEST;
			
			dummy = entity;
			CharUtils.poseCharacter(dummy, boothData.poses[0]);
			
			addDragToStickerTemplate(dummy);
			loaded();
		}
		
		private function checkHideTab():void
		{
			if(dragging &&!slidingTab)
				showTab(!showingTab);
		}
		
		private function setThreshold():void
		{
			Threshold(shellApi.inputEntity.get(Threshold)).offset = showingTab?320:420;
		}
		
		private function addDragToStickerTemplate(entity:Entity):void
		{
			InteractionCreator.addToEntity(entity, ["down","up",InteractionCreator.RELEASE_OUT]);
			var draggable:Draggable = new Draggable();
			draggable.drag.add(dragSticker);
			entity.add(draggable);
			entity.remove(Sleep);
		}
		
		private function dragSticker(entity:Entity):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH+DRAG_STICKER);
			
			dragging = true;
			var spatial:Spatial = entity.get(Spatial);
			origin = new Point(spatial.x, spatial.y);
			var disp:DisplayObjectContainer = EntityUtils.getDisplayObject(entity);
			prefabContainer = disp.parent;
			var pos:Point = DisplayUtils.localToLocal(disp, content);
			spatial.x = pos.x;
			spatial.y = pos.y;
			spatial.scale *= prefabContainer.scaleX;
			
			var draggable:Draggable = entity.get(Draggable);
			draggable.offsetX *= prefabContainer.scaleX;
			draggable.offsetY *= prefabContainer.scaleX;
			
			draggable.drop.addOnce(placeInScene);
			content.addChild(disp);
			if(input != null)
				input.selectable = false;
		}
		
		private function placeInScene(entity:Entity):void
		{
			dragging = false;
			var display:DisplayObjectContainer = EntityUtils.getDisplayObject(entity);
			
			var pos:Point = DisplayUtils.localToLocal(display, content);
			
			var contains:Boolean = border.getBounds(content).contains(pos.x, pos.y);
			
			if(contains && !showingTab)
			{
				pos = DisplayUtils.localToLocal(display,scene);
				selectOption(entity, pos);
			}
			else
				AudioUtils.play(this, SoundManager.EFFECTS_PATH+DROP_STICKER);
			
			var spatial:Spatial = entity.get(Spatial);
			spatial.x = origin.x;
			spatial.y = origin.y;
			spatial.scale /= prefabContainer.scaleX;
			prefabContainer.addChild(display);
			if(input != null)
				input.selectable = true;
		}
		
		override public function loaded():void
		{
			unique = false;
			
			if(boothData.music != null)
				AudioUtils.play(this, SoundManager.MUSIC_PATH+boothData.music, 1, true);
			
			trace(campaign);
			IAdManager(shellApi.adManager).track(campaign, "PhotoBoothOpened");
			
			var clip:DisplayObjectContainer = content["scene"];
			// fill screen and centerize everything
			content["sideBar"].height = content["bg"].height = content["tab"]["bg"].height = shellApi.viewportHeight;
			content["bg"].width = shellApi.viewportWidth;
			content["buttons"].y = clip.y = shellApi.viewportHeight / 2;
			clip.x = (shellApi.viewportWidth + 100) / 2;
			content["tab"]["down"].y = shellApi.viewportHeight - 30;
			content["instructions"].y = shellApi.viewportHeight - content["instructions"].height;
			
			var tf:TextField = TextUtils.refreshText(content["instructions"], "Billy Serif");
			tf.textColor = boothData.instructionsColor;// set text color via xml
			
			// save button
			clip = content["printBtn"];
			pinToEdge(clip, DisplayPositions.BOTTOM_RIGHT,10,10);
			ButtonCreator.createButtonEntity(clip,this);
			clip.addEventListener(MouseEvent.CLICK,savePhoto);
			
			//close button
			clip = content["closeBtn"];
			pinToEdge(clip, DisplayPositions.TOP_RIGHT,10,10);
			ButtonCreator.createButtonEntity(clip,this, closeButtonClicked);// close app?
			
			// tool bar
			clip = content["toolBar"];
			clip.y = shellApi.viewportHeight;
			clip.x = content["scene"].x;
			
			toolTab = EntityUtils.createSpatialEntity(this, clip);
			Display(toolTab.get(Display)).isStatic = false;
			
			setUpSlider(clip["alphaSlider"]);
			setUpSlider(clip["layerSlider"]);
			
			indexNumbers = new Dictionary();
			stickers = new Vector.<Entity>();
			
			var tabClip:MovieClip = content["tab"];
			stickerTab = EntityUtils.createSpatialEntity(this, tabClip);
			Display(stickerTab.get(Display)).isStatic = false;
			//threshold for checking if you have dragged a sticker beyond or back into the tab
			
			var threshold:Threshold = new Threshold("x",">",stickerTab,320);
			threshold.entered.add(checkHideTab);
			threshold.exitted.add(checkHideTab);
			shellApi.inputEntity.add(threshold);
			
			nameDisplay = TextUtils.refreshText(tabClip["nameDisplay"]["text"],"Billy Serif");
			nameDisplay.text= "";
			
			//set up tab buttons
			
			var tab:String;
			var subTab:String;
			var subTabClip:MovieClip;
			var tabEntity:Entity;
			var buttonClip:MovieClip;
			
			for(var i:int = 0; i < TABS.length; i++)
			{
				tab = TABS[i];
				buttonClip = content["buttons"][tab];
				if(buttonClip == null)
					continue;
				if(optimize)
					BitmapTimeline(ButtonCreator.createButtonEntity(content["buttons"][tab],this,Command.create(clickTab, i),null,null,null,true,true).add(new Id(tab+"Button")).get(BitmapTimeline)).bitmap.smoothing = true;
				else
					ButtonCreator.createButtonEntity(content["buttons"][tab], this, Command.create(clickTab, i)).add(new Id(tab+"Button"));
				
				indexNumbers[tab] = 0;
				
				subTabClip = tabClip[tab+TAB];
				if(subTabClip == null)//making it so empty containers are not required to be part of the asset
				{
					subTabClip = new MovieClip();
					subTabClip.name = tab+TAB;
					tabClip.addChild(subTabClip);
					tabClip[tab+TAB] = subTabClip;
					subTabClip.x = 90;
					DisplayUtils.moveToOverUnder(subTabClip, tabClip["up"], false);
				}
				
				tabEntity = EntityUtils.createSpatialEntity(this, subTabClip).add(new Id(subTabClip.name));
				EntityUtils.visible(tabEntity, false);
				if(tab == NPCS || tab == TEXT_FIELDS)
				{
					var subTabs:Array = tab == NPCS? NPCS_SUB_TABS:TEXT_FIELDS_SUB_TABS;
					
					if(tab == TEXT_FIELDS)
					{
						input = TextUtils.refreshText(subTabClip["textField"]["input"], boothData.fonts[0]);
						input.text = "Enter your text here.";
						input.autoSize = TextFieldAutoSize.LEFT;
						// when typing check to see if # of lines of text has changed and realign accordingly
						input.addEventListener(TextEvent.TEXT_INPUT,updateTextCentering);
						input.addEventListener(KeyboardEvent.KEY_DOWN,updateTextCentering);
						addDragToStickerTemplate(EntityUtils.createSpatialEntity(this, input.parent).add(new Id(input.name)));
					}
					for(var sub:int = 0; sub < subTabs.length; sub++)
					{
						subTab = subTabs[sub];
						//ButtonCreator.createButtonEntity(subTabClip[subTab],this, Command.create(clickTab, sub, true));
						ButtonCreator.createButtonEntity(subTabClip[subTab],this, Command.create(cycleThroughOptions,1,sub),null,null,null,true,true).add(new Id(subTab));
						indexNumbers[subTab] = 0;
					}
				}
			}
			// persistant ui
			ButtonCreator.createButtonEntity(tabClip["up"],this, Command.create(cycleThroughOptions, -1),null,null,null,true,true);
			ButtonCreator.createButtonEntity(tabClip["down"],this, Command.create(cycleThroughOptions, 1),null,null,null,true,true);
			ButtonCreator.createButtonEntity(tabClip["CLOSE"],this, hideTab,null,null,null,true,true);
			if(optimize)
				BitmapTimeline(ButtonCreator.createButtonEntity(content["buttons"]["clearBtn"],this,deletePhoto,null,null,null,true,true).add(new Id("clearButton")).get(BitmapTimeline)).bitmap.smoothing = true;
			else
				ButtonCreator.createButtonEntity(content["buttons"]["clearBtn"], this, deletePhoto).add(new Id("clearButton"));
			
			// scene containers
			scene = content["scene"]["container"];
			border = content["scene"]["border"];
			border.mouseChildren = border.mouseEnabled = false;
			
			
			
			clip = content["scene"]["bg"];
			//MovieClip(clip).graphics.beginFill(0xcccccc);
			//MovieClip(clip).graphics.drawRect(-border.width / 2, -border.height/2,border.width, border.height);
			bg = EntityUtils.createSpatialEntity(this,clip);
			bg.add(new StickerData(new SpatialData(bg.get(Spatial)), new StickerAssetData()));
			
			// transform tool
			follow = new FollowTarget();
			follow.offset = new Point(scene.parent.x, scene.parent.y);
			
			clip = content["tool"];
			convertContainer(clip);
			clip.mouseEnabled = false;
			clip["ring"].mouseEnabled = clip["ring"].mouseChildren = false;//purely aesthetic, dont want it in the way of clicking
			transformTool = EntityUtils.createSpatialEntity(this, clip);
			var edge:Edge = new Edge();
			edge.unscaled = clip.getBounds(clip);
			transformTool.add(edge).add(new MotionBounds(new Rectangle(100,0,shellApi.viewportWidth - 100, shellApi.viewportHeight)));
			Display(transformTool.get(Display)).alpha = .75;
			
			var entity:Entity;
			var toolClip:DisplayObjectContainer;
			var interaction:Interaction;
			var tool:TransformTool;
			
			var tools:Array = ["rotation", "scale"];
			
			for each (var string:String in tools)
			{
				toolClip = clip[string+"Tool"];
				entity = ButtonCreator.createButtonEntity(toolClip, this);
				interaction = InteractionCreator.addToComponent(toolClip, [InteractionCreator.RELEASE_OUT], entity.get(Interaction));
				interaction.up.add(releaseSticker);
				tool = new TransformTool();
				tool.addTransformData(string, string == "scale"?.01:1, string == "scale"?.05:15);
				tool.transformComplete.add(updateSticker);
				tool.transformStart.add(selectTool);
				entity.add(new Id(toolClip.name)).add(new TargetSpatial(null)).add(tool);
				EntityUtils.addParentChild(entity, transformTool);
			}
			
			interaction = ButtonCreator.createButtonEntity(clip["erase"],this,deleteSticker).get(Interaction);
			interaction.up.add(releaseSticker);
			interaction = ButtonCreator.createButtonEntity(clip["flipX"],this,Command.create(flip, "scaleX")).get(Interaction);
			interaction.up.add(releaseSticker);
			
			interaction = InteractionCreator.addToEntity(bg, ["click"]);
			interaction.click.add(deselectTool);
			
			showTab(false);
			deselectTool(null);
			
			if(boothData.promo != null)
			{
				promo = boothData.promo.asset;
				promo.x = border.parent.x;
				promo.y = border.parent.y;
				content.addChild(promo);
				border.width = promo.width;
				border.height = promo.height;
				convertContainer(promo);
				DisplayUtils.moveToOverUnder(promo, border.parent, false);
				
				clip = boothData.promo.button == null?promo:promo[boothData.promo.button];
				
				if(boothData.promo.popup != null)
					ButtonCreator.createButtonEntity(clip, this, Command.create(headerClicked, boothData.promo.popup));
			}
			
			if(boothData.headerData != null)
			{
				header = boothData.headerData.asset;
				content.addChild(header);
				DisplayUtils.moveToOverUnder(header, scene.parent);
				header.x = scene.parent.x;
				convertContainer(header);
				
				clip = boothData.headerData.button == null?header:header[boothData.headerData.button];
				
				if(boothData.headerData.popup != null)
					ButtonCreator.createButtonEntity(clip, this, Command.create(headerClicked, boothData.headerData.popup));
			}
			
			addOverlay();
			
			super.loaded();//"say your ready when when it looks presentable"
			
			SceneUtil.lockInput(this);
			// finish behind the scenes loading afterwards
			loadFiles(boothData.assets,true, true, setUpTabScrolling);
		}
		
		private function setUpTabScrolling():void
		{
			boothData.setUpAssets(this);
			/* tabs
			
			// tabs show different groups of assets available to place in scene
			
			// bgs are large static images that are just place in back ground
			
			// npcs are characters you can pose change their looks before making them a sticker
			
			// props are premade sticker stensils
			
			// stickers can be placed in scene moved around scaled and rotated
			
			// bgs can not be edited
			
			// templates are pre configured compositions of stickers and bg
			*/
			
			var tab:String;
			var tabEntity:Entity;
			
			for(var i:int = 0; i < TABS.length; i++)
			{
				tab = TABS[i];
				if(getEntityById(tab+"Button") == null)// if there is no button for it then there should be no tab for it either
					continue;
				
				tabEntity = getEntityById(tab+TAB);
				if(tab != NPCS && tab != TEXT_FIELDS)
					setUpBook(tabEntity, tab);
			}
			
			// after all the assets and data have finally been set up
			
			if(boothData.startingTemplate != null)//recreate a scene
			{
				recreateTemplate(getEntityById(boothData.startingTemplate));
			}
			else// or just make sure everything is set to default
			{
				SkinUtils.applyLook(dummy,boothData.npcs[0].stickers[0].look,true);
				CharUtils.poseCharacter(dummy, boothData.poses[indexNumbers[POSES]]);
				Id(dummy.get(Id)).id = boothData.npcs[0].stickers[0].id;
			}
			
			SceneUtil.lockInput(this, false);
			
			itemGroup = getGroupById(ItemGroup.GROUP_ID) as ItemGroup;
			
			if(DataUtils.validString(boothData.adCardEntered))
			{
				if(!shellApi.checkHasItem(boothData.adCardEntered, cardType))
					itemGroup.showAndGetItem(boothData.adCardEntered, cardType, null, screen);
			}
		}
		
		private function releaseSticker(entity:Entity):void
		{
			if(currentSticker != null)
				Draggable(currentSticker.get(Draggable)).onDrop();
		}
		
		protected function updateTextCentering(...args):void
		{
			input.y = - input.height / 2;
		}
		
		private function closeButtonClicked(entity:Entity):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH+CLICK_EXIT);
			IAdManager(shellApi.adManager).track(campaign, "PhotoBoothClosed");
			close();
		}
		
		private function recreateScene():void
		{
			if(currentLayout.stickerNumber == currentLayout.sceneStickers.length)//reset everything when finished making scene
			{
				if(input != null)
					input.text = "Enter your text here.";
				
				Skin(dummy.get(Skin)).revertAll();
				
				var index:int = 0;
				
				var look:LookData = boothData.npcs[index].stickers[0].look.duplicate();
				look.fillWithEmpty();
				
				SkinUtils.applyLook(dummy,look,true);
				CharUtils.poseCharacter(dummy, boothData.poses[index]);
				Id(dummy.get(Id)).id = boothData.npcs[index].stickers[0].id;
				SkinUtils.setEyeStates(dummy, boothData.expressions[0].lookData.getValue(SkinUtils.EYE_STATE), boothData.expressions[0].pupilState);
				currentLayout.stickerNumber = 0;
				indexNumbers[NPCS] = 0;
				currentLayout = null;
				
				unique = false;
				
				SceneUtil.lockInput(this, false);
				
				return;
			}
			
			if(currentLayout.stickerNumber == 0)
			{
				AudioUtils.play(this, SoundManager.EFFECTS_PATH+SELECT_TEMPLATE);
				SceneUtil.lockInput(this);
				showTab(false);
				if(currentLayout.bg != null)
					createElementInScene(currentLayout.bg.duplicate());//make bg first
			}
			
			var stickerData:StickerData = StickerData(currentLayout.sceneStickers[currentLayout.stickerNumber]).duplicate()
			++currentLayout.stickerNumber;
			createElementInScene(stickerData);
		}
		
		private var loadingTimer:TimedEvent;// if loading takes too long, skip it
		
		private function createElementInScene(stickerData:StickerData):void
		{
			var asset:StickerAssetData;
			if(stickerData.asset.tab == NPCS)
			{
				var pose:CharacterPoseData = boothData.poses[stickerData.asset.pose];
				CharUtils.poseCharacter(dummy, pose);
				stickerData.asset.url = pose.url;
				var lookData:LookData = stickerData.asset.look.duplicate();
				// any parts not specified set to empty, this overwrites part values set from expressions
				lookData.fillWithEmpty();
				
				SkinUtils.applyLook(dummy,lookData,true,Command.create(appliedLook, stickerData));
				
				loadingTimer = SceneUtil.delay(this, 1, Command.create(tookTooLongToLoad, stickerData));
				return;
			}
			
			if(stickerData.asset.tab == TEXT_FIELDS)
			{
				recreateText(stickerData);
				return;
			}
			
			var stickerSheet:StickerSheet = boothData[stickerData.asset.tab][stickerData.asset.index];
			asset = stickerSheet.getStickerById(stickerData.asset.id);
			// not as efficient, but is less susceptible to failing from photobooth to photobooth
			if(asset == null)
				asset = boothData.getStickerAssetData(stickerData.asset.id, stickerData.asset.tab);
			
			stickerData.asset.url = asset.url;
			
			var sprite:Sprite = createSprite(asset.asset.getChildAt(0));
			
			if(stickerData.asset.tab == BGS)
			{
				createBackground(sprite, stickerData);
				return;
			}
			
			createSticker(sprite, stickerData);
			recreateScene();
		}
		
		private function tookTooLongToLoad(stickerData:StickerData):void
		{
			//force things to keep going if they are going to load infinitely
			// not sure if we want to skip the loading, or skip the sticker all together
			trace("took too long so we are going to skip it");
			loadingTimer = null;
			appliedLook(dummy, stickerData);
		}
		
		private function recreateText(stickerData:StickerData):void
		{
			var textData:StickerTextData = stickerData.asset.text;
			input.defaultTextFormat = new TextFormat(textData.font, textData.size, textData.color);
			input.text = textData.text;
			updateTextCentering();
			createSticker(createSprite(input.parent), stickerData);
			recreateScene();
		}
		
		private function createSprite(asset:DisplayObject):Sprite
		{
			var scale:Number = Math.max(shellApi.viewportWidth / asset.width, shellApi.viewportHeight / asset.height) / 5;
			
			if(PlatformUtils.isMobileOS || scale < 1)
				scale = 1;
			
			var wrapper:BitmapWrapper = convertToBitmapSprite(asset,null, false,scale);
			
			wrapper.bitmap.smoothing = true;
			return wrapper.sprite;
		}
		
		private function appliedLook(npc:Entity, stickerData:StickerData):void
		{
			if(loadingTimer)
			{
				loadingTimer.stop();
				loadingTimer = null;
			}
			if(stickerData.asset.expression != null)
				SkinUtils.setEyeStates(dummy, stickerData.asset.look.getValue(SkinUtils.EYE_STATE), stickerData.asset.expression.pupilState,true);
			
			TimelineUtils.stopAll(dummy);
			
			// need to go through parts and make sure that they are flattened
			
			// needs a couple frames to make sure everything is in position
			SceneUtil.delay(this,5, Command.create(createNpcSticker, npc, stickerData)).countByUpdate = true;
			
			//createNpcSticker(npc, stickerData);
		}
		
		private function createNpcSticker(npc:Entity, stickerData:StickerData):void
		{
			var sprite:Sprite = createSprite(EntityUtils.getDisplayObject(npc));
			
			createSticker(sprite, stickerData);
			
			recreateScene();
		}
		
		private function createBackground(sprite:Sprite, stickerData:StickerData):void
		{
			var display:DisplayObjectContainer = EntityUtils.getDisplayObject(bg);
			if(display.numChildren > 0)
				display.removeChildAt(0);
			
			display.addChild(sprite);
			border.width = sprite.width;
			border.height = sprite.height;
			StickerData(bg.get(StickerData)).asset = stickerData.asset;
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH+SELECT_BG);
			
			addOverlay();
		}
		
		private function addOverlay():void
		{
			var overlay:MovieClip = border.parent.getChildAt(border.parent.numChildren - 1) as MovieClip;
			
			if(overlay == border)
			{
				overlay = new MovieClip();
				border.parent.addChild(overlay);
				overlay.mouseChildren = overlay.mouseEnabled = false;
			}
			
			var rect:Rectangle = new Rectangle(-border.parent.x, -border.parent.y, shellApi.viewportWidth, shellApi.viewportHeight);
			overlay.graphics.clear();
			if(isNaN(boothData.theme))
				overlay.graphics.beginBitmapFill(boothData.theme);
			else
				overlay.graphics.beginFill(boothData.theme);
			overlay.graphics.drawRect(rect.x, rect.y, rect.width, rect.height);
			rect.copyFrom(border.getBounds(border.parent));
			overlay.graphics.drawRect(rect.x,rect.y, rect.width, rect.height);
			
			if(header != null)
				header.y = (shellApi.viewportHeight / 2 - rect.height / 2) / 2;
		}
		
		private function createSticker(sprite:Sprite, stickerData:StickerData):Entity
		{
			var entity:Entity = EntityUtils.createSpatialEntity(this, sprite, scene);
			entity.add(stickerData);
			stickerData.position.positionSpatial(entity.get(Spatial));
			InteractionCreator.addToEntity(entity, ["down","up",InteractionCreator.RELEASE_OUT]);
			var draggable:Draggable = new Draggable();
			draggable.forward = false;
			draggable.drop.add(updateSticker);
			draggable.drop.add(dropSticker);
			draggable.drag.add(selectSticker);
			entity.add(draggable);
			stickers.push(entity);
			entity.remove(Sleep);
			Display(entity.get(Display)).alpha = stickerData.asset.alpha;
			currentSticker = entity;
			if(currentLayout == null)
				selectSticker(entity);
			return entity;
		}
		
		private function dropSticker(entity:Entity):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH+DROP_STICKER);
		}
		//book is what we are using to scroll through different sticker sheets in a tab
		private function setUpBook(entity:Entity, tab:String):void
		{
			var book:Book = new Book(1,boothData[tab].length,240,shellApi.viewportHeight);
			book.wrap = true;
			book.rate = 5;
			book.section = book.SECTION_VERTICAL;
			
			entity.add(new SpatialAddition()).add(book);
			
			var sprite:Sprite;
			var displays:Array;
			var asset:*;
			var sticker:StickerAssetData;
			var sheet:StickerSheet;
			var sheets:Vector.<StickerSheet> = boothData[tab];
			var clip:MovieClip;
			
			for(var i:int = 0; i < sheets.length; ++i)
			{
				displays = [];
				sheet = sheets[i];
				sprite = new Sprite();
				sprite.y = i * book.pageHeight;
				for(var j:int = 0; j < sheet.stickers.length; ++j)
				{
					sticker = sheet.stickers[j];
					asset = sticker.asset;
					switch(tab)
					{
						case TEMPLATES:
						{
							ButtonCreator.createButtonEntity(asset, this, recreateTemplate).add(new Id(sticker.id));
							break;
						}
						case BGS:// bgs have a frame clip which says it only wants a certain part of the image to be used as the actual bg
						{
							var frame:MovieClip = asset["frame"];
							clip = new MovieClip();
							clip.addChild(BitmapUtils.createBitmapSprite(asset.getChildAt(0),1,frame.getBounds(frame)));
							asset = new MovieClip();
							ButtonCreator.createButtonEntity(clip, this, selectOption).add(new Id(sticker.id));
							asset.addChild(clip);
							sticker.asset = asset;
							break;
						}
						default:
						{
							if(optimize)
								addDragToStickerTemplate(EntityUtils.createSpatialEntity(this, convertToBitmapSprite(asset.getChildAt(0),asset).sprite).add(new Id(sticker.id)));
							else
								addDragToStickerTemplate(EntityUtils.createSpatialEntity(this, asset.getChildAt(0)).add(new Id(sticker.id)));
							break;
						}
					}
					sprite.addChild(asset);
					displays.push(asset);
				}
				alignAssets(displays,sheet.columns);
				EntityUtils.createSpatialEntity(this, sprite, EntityUtils.getDisplayObject(entity));
			}
		}
		
		// given a bitmap and scene data create a template button to recreate that scene
		private function addTemplateToTab(bitmapData:BitmapData, sceneData:PhotoBoothSceneData):void
		{
			// create asset
			var asset:MovieClip = new MovieClip();
			var bitmap:Bitmap = new Bitmap(bitmapData);
			asset.addChild(bitmap);
			bitmap.x = -bitmap.width / 2;
			bitmap.y = -bitmap.height /2;
			
			var entity:Entity = getEntityById(TEMPLATES+TAB)
			var book:Book = entity.get(Book);
			
			var container:DisplayObjectContainer = EntityUtils.getDisplayObject(entity);
			
			var sheet:StickerSheet;
			var sprite:Sprite;
			
			if(tempsSaved % TEMPS_PER_PAGE == 0)// add new page
			{
				book.numPages++;
				sheet = new StickerSheet();
				sheet.title = TEMP;
				boothData.templates.push(sheet);
				
				sprite = new Sprite();
				sprite.y = container.numChildren * book.pageHeight;
				container.addChild(sprite);
			}
			else// continue on from last page
			{
				sprite = container.getChildAt(container.numChildren - 1) as Sprite;
				sheet= boothData.templates[boothData.templates.length - 1];
			}
			
			sprite.addChild(asset);
			
			var id:String = TEMP+tempsSaved;
			
			ButtonCreator.createButtonEntity(asset, this, recreateTemplate,null,null,null,true,true).add(new Id(id));
			
			//create data
			
			var data:StickerAssetData = new StickerAssetData();
			data.id = id;
			data.index = boothData.templates.length;
			data.tab=TEMPLATES;
			data.asset = asset;
			sheet.stickers.push(data);
			
			//store data
			
			boothData.templateDatas[id] = sceneData;
			
			var assets:Array = [];
			
			for(var i:int = 0 ; i < sprite.numChildren; i++)
			{
				assets.push(sprite.getChildAt(i));
			}
			
			// allign and position in page
			alignAssets(assets,1);
			
			++tempsSaved;
		}
		
		private function alignAssets(assets:Array, columns:int):void
		{
			GridAlignment.distributeVerticallyScaled(assets,new Rectangle(20,100,200, shellApi.viewportHeight - 160),columns,20);
		}
		
		private function recreateTemplate(entity:Entity):void
		{
			var id:String = entity.get(Id).id;
			IAdManager(shellApi.adManager).track(campaign, "TemplateUsed", id);
			if(boothData.templateDatas.hasOwnProperty(id))
				currentLayout = boothData.templateDatas[ id ];
			else
			{
				for(var i:int = 0; i < TABS.length; i++)
				{
					var tab:String = TABS[i];
					if(tab != BGS)
						continue;
					var stickerSheet:Vector.<StickerSheet> = boothData[TABS[i]];
					for(var s:int = 0; s < stickerSheet.length; s++)
					{
						var sheet:StickerSheet = stickerSheet[s];
						var sticker:StickerAssetData = sheet.getStickerById(id);
						if(sticker)
						{
							tabNumber = i;
							indexNumbers[BGS] = s;
							break;
						}
					}
				}
				// then use it
				Interaction(entity.get(Interaction)).click.dispatch(entity);
				tabNumber = 0;
				indexNumbers[BGS] = 0;
				return;
			}
			if(stickers.length > 0)
				deletePhoto(entity, recreateScene);
			else
				recreateScene();
		}
		
		private function setUpSlider(clip:MovieClip):void
		{
			if(getSystem(BoundsCheckSystem) == null)
				addSystem(new BoundsCheckSystem());
			var slider:MovieClip = clip["slider"];
			var entity:Entity = ButtonCreator.createButtonEntity(slider, this);
			Display(entity.get(Display)).isStatic = false;
			var rect:Rectangle = clip["bar"].getBounds(clip);
			rect.left += slider.width /2;
			rect.right -= slider.width / 2;
			InteractionCreator.addToComponent(slider, [InteractionCreator.RELEASE_OUT], entity.get(Interaction));
			var drag:Draggable = new Draggable("x");
			drag.dragging.add(setProperty);
			entity.add(new Slider()).add(new Ratio()).add(drag).add(new MotionBounds(rect)).add(new Id(clip.name));
			trace(entity.getAll());
		}
		
		private function setProperty(entity:Entity):void
		{
			if(currentSticker == null)
				return;
			
			var display:Display = currentSticker.get(Display);
			var ratio:Ratio = entity.get(Ratio);
			
			var currentTool:String = entity.get(Id).id;
			
			if(currentTool == ALPHA)
				setAlpha(display, ratio);
			else
				setLayer(display, ratio);
			
			unique = true;
		}
		
		private function setAlpha(display:Display, ratio:Ratio, update:Boolean = false):void
		{
			if(update)
				ratio.decimal = display.alpha;
			else
			{
				display.alpha = ratio.decimal;
				StickerData(currentSticker.get(StickerData)).asset.alpha = display.alpha;
			}
		}
		
		private function setLayer(display:Display, ratio:Ratio, update:Boolean = false):void
		{
			if(update)
				ratio.decimal = display.container.getChildIndex(display.displayObject) / (display.container.numChildren - 1);
			else
			{
				var index:int = int(ratio.decimal * (display.container.numChildren - 1));
				display.container.setChildIndex(display.displayObject, index);
				stickers.splice(stickers.indexOf(currentSticker), 1);
				stickers.splice(index,0,currentSticker);
			}
		}
		
		private function updateProperties():void
		{		
			var display:Display = currentSticker.get(Display);
			
			var ratio:Ratio = getEntityById(ALPHA).get(Ratio);
			setAlpha(display, ratio, true);
			
			ratio = getEntityById(LAYER).get(Ratio);
			setLayer(display, ratio, true);
		}
		
		private function flip(entity:Entity, property:String):void
		{
			if(currentSticker == null)
				return;
			
			Spatial(currentSticker.get(Spatial))[property] *= -1;
			
			updateSticker(entity);
		}
		
		// create the sticker element in a certain position in the scene
		private function selectOption(entity:Entity, position:Point = null):void
		{
			var tab:String = TABS[tabNumber];
			
			if(tab != BGS)// placing a sticker
			{
				// limiting stickers
				if(stickers.length >= stickerLimit && stickerLimit > 0)
				{
					var popup:ConfirmationDialogBox = addChildGroup(new ConfirmationDialogBox(1, "You can not put on any more stickers, delete some before adding more.")) as ConfirmationDialogBox;
					popup.init(content["popupContainer"]);
					return;
				}
			}
			else
				position = new Point();
			
			// asset data
			var assetData:StickerAssetData = new StickerAssetData();
			assetData.tab = tab;
			assetData.index = indexNumbers[tab];
			assetData.id = entity.get(Id).id;
			
			var sprite:Sprite = createSprite(EntityUtils.getDisplayObject(entity));
			
			// npcs have special data
			if(entity.get(Skin))
			{
				assetData.look = SkinUtils.getLook(entity, false);
				assetData.look.fillWithEmpty();
				assetData.pose  = indexNumbers[POSES];
				assetData.url = boothData.poses[assetData.pose].url;
				assetData.expression = boothData.expressions[indexNumbers[EXPRESSIONS]].duplicate();
			}
			else
			{
				var page:Vector.<StickerSheet> = boothData[tab];
				assetData.url = page[assetData.index].getStickerById(assetData.id).url;
			}
			
			if(tab == TEXT_FIELDS)//text fields have special data
			{
				var text:StickerTextData = new StickerTextData();
				var format:TextFormat = input.defaultTextFormat;
				text.text = input.text;
				text.font = format.font;
				text.color = format.color as Number;
				text.size = format.size as Number;
				assetData.text = text;
			}
			
			// positional data
			var spatialData:SpatialData = new SpatialData(entity.get(Spatial));
			sprite.x = spatialData.x = position.x;
			sprite.y = spatialData.y = position.y;
			
			// tracking
			var info:String = tab==NPCS? "pose: " + assetData.pose + " expression: " + indexNumbers[EXPRESSIONS] + " item: " + indexNumbers[ITEMS]:null;
			//track people really want their variable names to be CamelCase...
			var firstLetter:String = tab.substr(0,1).toUpperCase();
			var rest:String = tab.substr(1);
			
			IAdManager(shellApi.adManager).track(campaign,firstLetter+rest+"StickerPlaced", assetData.id, info);
			
			//create
			// swap bgs
			if(tab == BGS)
			{
				createBackground(sprite, new StickerData(spatialData, assetData));
			}
			else
			{
				//place sticker
				createSticker(sprite, new StickerData(spatialData,assetData));
			}
			
			unique = true;
		}
		
		private function updateSticker(entity:Entity):void
		{
			if(entity.get(Button))
				Button(entity.get(Button)).isSelected = false;
			if(currentSticker != null)
			{
				var rect:Rectangle = EntityUtils.getDisplayObject(currentSticker).getBounds(scene);
				var bounds:Rectangle = border.getBounds(border);
				// delete sticker if it is not in the picture
				if(rect.right < bounds.left || rect.left > bounds.right || rect.top > bounds.bottom || rect.bottom < bounds.top)
					deleteSticker(currentSticker);
				else
					StickerData(currentSticker.get(StickerData)).updatePosition(currentSticker.get(Spatial));
				
				unique = true;
			}
		}
		
		private function selectSticker(sticker:Entity):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH+DRAG_STICKER);
			
			showTab(false);
			
			currentSticker = clickThroughSticker(sticker);
			
			if(currentSticker == null)
			{
				deselectTool(null);
				return;
			}
			
			showTools();
			
			updateProperties();
			
			EntityUtils.visible(transformTool);
			var spatial:Spatial = currentSticker.get(Spatial);
			
			for each(var tool:Entity in transformTool.get(Children).children)
			{
				TargetSpatial(tool.get(TargetSpatial)).target = spatial;
			}
			follow.target = spatial;
			if(transformTool.get(FollowTarget) == null)
				transformTool.add(follow);
		}
		
		// if you click on a transparent part of a bit map, see if you can click on something behind it
		private function clickThroughSticker(sticker:Entity):Entity
		{
			var entity:Entity;
			
			var bitmap:Bitmap = EntityUtils.getDisplayObject(sticker).getChildAt(0) as Bitmap;
			
			// this is seperate from the sprites alpha so no matter what the sprites alpha is, this alpha should always be the same
			var alpha:uint = ((bitmap.bitmapData.getPixel32(int(bitmap.mouseX), int(bitmap.mouseY)) >> 24 ) & 0xFF);
			
			var alphaRange:Number = 32;// it seems some minor coloration interferes with the intent // opaque = 255
			
			if(alpha < alphaRange)
			{
				for (var i:int = stickers.length - 1; i >=0; --i)
				{
					entity = stickers[i];
					if(entity != sticker)
					{
						bitmap = EntityUtils.getDisplayObject(entity).getChildAt(0) as Bitmap;
						if(bitmap.getRect(bitmap).contains(bitmap.mouseX, bitmap.mouseY))
						{
							alpha = ((bitmap.bitmapData.getPixel32(int(bitmap.mouseX), int(bitmap.mouseY)) >> 24 ) & 0xFF);
							if(alpha > alphaRange)
							{
								Draggable(entity.get(Draggable)).onDrag();
								Draggable(sticker.get(Draggable)).onDrop();
								Interaction(sticker.get(Interaction)).up.addOnce(Draggable(entity.get(Draggable)).onDrop);
								return entity;
							}
						}
					}
				}
			}
			else
				return sticker;
			
			Draggable(sticker.get(Draggable)).onDrop();
			
			return null;
		}
		
		private function deleteSticker(entity:Entity):void
		{
			if(currentSticker != null)
			{
				AudioUtils.play(this, SoundManager.EFFECTS_PATH+DELETE_STICKER);
				var stickerData:StickerData = currentSticker.get(StickerData);
				IAdManager(shellApi.adManager).track(campaign,"StickerDeleted",stickerData.asset.tab,stickerData.asset.id);
				
				var i:int = stickers.indexOf(currentSticker);
				stickers.splice(i,1);
				var bitmap:Bitmap = EntityUtils.getDisplayObject(currentSticker).getChildAt(0) as Bitmap;
				bitmap.bitmapData.dispose();
				transformTool.remove(FollowTarget);
				removeEntity(currentSticker);
				deselectTool(null);
				unique = true;
			}
		}
		
		private function deselectTool(entity:Entity):void
		{
			EntityUtils.visible(transformTool, false);
			currentSticker = null;
			showTools(false);
		}
		
		private function selectTool(entity:Entity):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH+DRAG_STICKER);
			Button(entity.get(Button)).isSelected = true;
		}
		
		private function cycleThroughOptions(entity:Entity, direction:int, subTabNumber:int = -1):void
		{
			var tab:String = subTabNumber >= 0? entity.get(Id).id : TABS[tabNumber];
			if(tab == TEXT_FIELDS || boothData[tab].length == 1)
				return;
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH+SCROLL_OPTIONS);
			
			var index:int = indexNumbers[tab];
			index += direction;
			if(index >= boothData[tab].length)
				index = 0;
			if(index < 0)
				index = boothData[tab].length - 1;
			indexNumbers[tab] = index;
			
			if(subTabNumber == -1)
				displayTitle(tab);
			
			var lookData:LookData;
			
			switch(tab)
			{
				case NPCS:
				{
					Id(dummy.get(Id)).id = boothData[tab][index].stickers[0].id;
					Skin(dummy.get(Skin)).revertAll();
					// create duplicate of look to prevent adjustments from applying to original
					lookData = boothData[tab][index].stickers[0].look.duplicate();
					// when changing characters, reset expressions back to none
					indexNumbers[EXPRESSIONS] = 0;	
					// carry poses over between npcs
					CharUtils.poseCharacter(dummy, boothData.poses[indexNumbers[POSES]]);
					var item:LookAspectData = lookData.getAspect(SkinUtils.ITEM);
					// if npc look specifies an item, use that item and reset item tab back to 0, otherwise allow item from tab to carry over
					if( item == null || item.value == "empty" )
					{
						item = boothData.items[indexNumbers[ITEMS]].getAspect(SkinUtils.ITEM);
						lookData.applyAspect(item);
					}
					else
						indexNumbers[ITEMS] = 0;
					// any parts not specified set to empty, this overwrites part values set from expressions
					lookData.emptyAllFill();
					SkinUtils.applyLook(dummy, lookData, true,lookUpdated);
					break;
				}
				case EXPRESSIONS:
				{
					boothData.expressions[index].applyExpression(dummy);
					break;
				}
				case ITEMS:
				{
					SkinUtils.applyLook(dummy, boothData[tab][index],true);
					break;
				}
				case POSES:
				{
					CharUtils.poseCharacter(dummy, boothData.poses[index]);
					break;
				}
				case STICKERS:
				case BGS:
				case TEMPLATES:
				{
					Book(getEntityById(tab+TAB).get(Book)).page += direction;
					break;
				}
				case FONTS:
				case SIZES:
				case COLORS:
				{
					var format:TextFormat = input.getTextFormat();
					format = new TextFormat(boothData.fonts[indexNumbers[FONTS]], boothData.sizes[indexNumbers[SIZES]], boothData.colors[indexNumbers[COLORS]]);
					input.defaultTextFormat = format;
					input.setTextFormat(format);
					updateTextCentering();
				}
			}
		}
		
		private function lookUpdated(entity:Entity):void
		{
			TimelineUtils.stopAll(entity);
		}
		
		private function clickTab(tab:Entity, tabNumber:int, subTab:Boolean = false):void
		{
			//AudioUtils.play(this, SoundManager.EFFECTS_PATH);
			if(this.tabNumber == tabNumber && showingTab && !subTab)
			{
				showTab(false);
				return;
			}
			
			if(subTab)
			{
				this.subTabNumber = tabNumber;
				return;
			}
			else
			{
				subTab = -1;
				this.tabNumber = tabNumber;
			}
			
			if(showingTab)
				showTab(false, refreshTab);
			else
				refreshTab();
		}
		
		private function refreshTab():void
		{
			var entity:Entity;
			for(var i:int = 0; i < TABS.length; i++)
			{
				entity = getEntityById(TABS[i]+TAB);
				if(entity != null)
					EntityUtils.visible(entity, false);
			}
			
			var tab:String = TABS[tabNumber];
			displayTitle(tab);
			
			entity = getEntityById(tab+TAB);
			EntityUtils.visible(entity);
			showTab();
		}
		
		private function displayTitle(tab:String):void
		{
			if(tab == TEXT_FIELDS)
				nameDisplay.text = "text";
			else
			{
				if(boothData[tab].length > 0)
					nameDisplay.text = boothData[tab][indexNumbers[tab]].title;
			}
		}
		
		private function showTools(show:Boolean = true):void
		{
			var y:Number = show?shellApi.viewportHeight:shellApi.viewportHeight + 100;
			if(PlatformUtils.isMobileOS)
			{
				Spatial(toolTab.get(Spatial)).y = y;
			}
			else
			{
				toolTab.remove(Tween);
				TweenUtils.entityTo(toolTab, Spatial, .25, {y:y});
			}
		}
		
		private function showTab(show:Boolean = true, onComplete:Function = null):void
		{
			slidingTab = true;
			
			var sound:String = show?OPEN_TAB:CLOSE_TAB;
			if(show != showingTab)
				AudioUtils.play(this, SoundManager.EFFECTS_PATH+sound);
			
			showingTab = show;
			
			if(show)
				deselectTool(null);
			
			setThreshold();
			
			var x:Number = show?0:-320;
			
			if(PlatformUtils.isMobileOS)
			{
				Spatial(stickerTab.get(Spatial)).x = x;
				transitionComplete(onComplete);
			}
			else
			{
				stickerTab.remove(Tween);
				TweenUtils.entityTo(stickerTab, Spatial, .25, {x:x, onComplete:Command.create(transitionComplete,onComplete)});
			}
		}
		
		private function transitionComplete(onComplete:Function = null):void
		{
			slidingTab = false;
			if(onComplete)
				onComplete();
		}
		
		private function hideTab(entity:Entity):void
		{
			showTab(false);
		}
		
		private function deletePhoto(entity:Entity, onComplete:Function = null):void
		{
			var popup:ConfirmationDialogBox = addChildGroup(new ConfirmationDialogBox(2, "Do you want to clear your canvas? You will lose all of your changes if you continue.",Command.create(clearPhoto, onComplete))) as ConfirmationDialogBox;
			popup.init(content["popupContainer"]);
		}
		
		private function clearPhoto(onComplete:Function = null):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH+DELETE_SCENE);
			var entity:Entity;
			var bitmap:Bitmap;
			var sprite:Sprite
			
			if(EntityUtils.getDisplayObject(bg).numChildren > 0)
			{
				sprite = EntityUtils.getDisplayObject(bg).removeChildAt(0) as Sprite;
				bitmap = sprite.getChildAt(0) as Bitmap;
				bitmap.bitmapData.dispose();
				StickerData(bg.get(StickerData)).asset.tab = null;
			}
			
			for(var i:int = 0; i < stickers.length; i++)
			{
				entity = stickers[i];
				bitmap = EntityUtils.getDisplayObject(entity).getChildAt(0) as Bitmap;
				bitmap.bitmapData.dispose();
				removeEntity(entity);
			}
			stickers = new Vector.<Entity>();
			deselectTool(null);
			if(onComplete != null)
				onComplete();
			
			unique = false;
		}
		
		private function headerClicked(entity:Entity, popupData:DialogBoxData):void// for them
		{
			showTab(false);
			
			var popup:ConfirmationDialogBox = addChildGroup(new ConfirmationDialogBox(2, popupData.text)) as ConfirmationDialogBox;
			
			popup.configData(popupData.asset, popupData.prefix, popupData.confirmText, popupData.cancelText);
			
			popup.init(content["popupContainer"]);
			popup.ready.add(Command.create(confirmationReady, popupData));
		}
		
		private function confirmationReady(popup:ConfirmationDialogBox, headerData:DialogBoxData):void
		{
			setUpConfirmButton(popup.screen.okButton, headerData);
		}
		//after dialog box is set up access ok button so we can addEventlistener directly (sand box issue for saving)
		private function setUpConfirmButton(clip:DisplayObjectContainer, headerData:DialogBoxData):void
		{
			switch(headerData.type)
			{
				case DialogBoxData.CONTEST:
				{
					convertSceneToData();
					clip.addEventListener(MouseEvent.CLICK,savePicToServer);
					break;
				}
				case DialogBoxData.AD:
				{
					clip.addEventListener(MouseEvent.CLICK, clickOnAd);
					break;
				}
				case DialogBoxData.DEV:
				{
					convertSceneToData();
					clip.addEventListener(MouseEvent.CLICK,savePicToXML);
					break;
				}
				case DialogBoxData.DEFAULT:
				{
					convertSceneToData();
					formFileName();
					clip.addEventListener(MouseEvent.CLICK,savePicToProfile);
				}
			}
		}
		
		protected function savePicToProfile(event:MouseEvent):void
		{
			if(!unique)
				return;
			
			IAdManager(shellApi.adManager).track(campaign,"PhotoBoothSavedToProfile");
			
			var profile:ProfileData = shellApi.profileManager.active;
			
			trace("saving " + fileName + " to " + profile.login + "'s profile");
			
			var postVars:URLVariables = new URLVariables();
			
			postVars.login = profile.login;
			postVars.pass_hash = profile.pass_hash;
			postVars.dbid = profile.dbid;
			postVars.photo_name = fileName;
			postVars.photo = currentLayout.toXML();
			
			var url:String = super.shellApi.siteProxy.secureHost + "/interface/PhotoBooth/save";
			var req:URLRequest = new URLRequest(url);
			req.method = URLRequestMethod.POST;
			req.data = postVars;
			
			var loader:URLLoader = new URLLoader(req);
			loader.addEventListener(Event.COMPLETE,savedToProfile);
			loader.addEventListener(IOErrorEvent.IO_ERROR, saveToPforileError);
			loader.load(req);
		}
		
		protected function saveToPforileError(event:IOErrorEvent):void
		{
			trace(event.toString());
			if(boothData.submitPopup != null)
			{
				var popup:ConfirmationDialogBox = addChildGroup(new ConfirmationDialogBox(boothData.submitPopup.numBtns, boothData.submitPopup.alternateText)) as ConfirmationDialogBox;
				
				popup.configData(boothData.submitPopup.asset, boothData.submitPopup.prefix, boothData.submitPopup.confirmText, boothData.submitPopup.cancelText);
				
				popup.init(content["popupContainer"]);
			}
		}
		
		protected function savedToProfile(event:Event):void
		{
			var data:Object = JSON.parse(event.target.data);
			trace(data.answer);
			if(boothData.submitPopup != null)
			{
				var popup:ConfirmationDialogBox = addChildGroup(new ConfirmationDialogBox(boothData.submitPopup.numBtns, boothData.submitPopup.text)) as ConfirmationDialogBox;
				
				popup.configData(boothData.submitPopup.asset, boothData.submitPopup.prefix, boothData.submitPopup.confirmText, boothData.submitPopup.cancelText);
				
				popup.init(content["popupContainer"]);
			}
		}
		
		private function clickOnAd(e:Event):void
		{
			shellApi.adManager.visitSponsor(campaign);
		}
		
		private function savePicToServer(e:Event):void// for them
		{
			if(!unique)
				return;
			IAdManager(shellApi.adManager).track(campaign,"PhotoBoothSubmited");
			
			var request:DataStoreRequest = DataStoreRequest.gameImageStorageRequest(PNGEncoder.encode(picData ), 'png', currentLayout.toXML(), campaign);
			
			shellApi.siteProxy.store(request);
		}
		
		private function formFileName():void
		{
			var time:Date = new Date();
			
			fileName = campaign + "_" + time.toUTCString();
			
			while(fileName.indexOf(":") != -1)
				fileName = fileName.replace(":", "-");
		}
		
		private function savePhoto(e:MouseEvent):void
		{
			if(getGroupById(ConfirmationDialogBox.GROUP_ID))
				return;
			
			showTab(false);
			
			convertSceneToData();
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH+CLICK_SAVE);
			
			formFileName();
			
			if(PlatformUtils.isMobileOS)
			{
				IAdManager(shellApi.adManager).track(campaign,"PhotoBoothSaved");
				// only lock input if valid
				SceneUtil.lockInput(this, shellApi.saveBitmapDataToCameraRoll(picData, fileName+".png", savedToCameraRoll, Command.create(savedToCameraRoll, "Save failed!")));
			}
			else
			{
				if(PlatformUtils.inBrowser && !shellApi.profileManager.active.isGuest)
				{
					savePicToProfile(e);
				}
				else
				{
					var file:FileReference = new FileReference();
					file.save(PNGEncoder.encode(picData ),fileName+".png");
					file.addEventListener(Event.COMPLETE, saveComplete);
					if(PlatformUtils.isDesktop && !PlatformUtils.inBrowser && AppConfig.debug)// trying to make absolutely sure that this is ONLY being called locally
					{
						file.addEventListener(Event.COMPLETE, savePicToXML);
						addTemplateToTab(picData, currentLayout.duplicate());
					}
				}
			}
		}
		
		protected function saveComplete(...args):void
		{
			trace("pic saved");
			if(DataUtils.validString(boothData.adCardSaved))
			{
				if(!shellApi.checkHasItem(boothData.adCardSaved, cardType))
					itemGroup.showAndGetItem(boothData.adCardSaved, cardType, null, screen);
			}
		}
		
		private function savedToCameraRoll(message:String = "Save Successful!"):void
		{
			var success:Boolean = message == "Save Successful!";
			SceneUtil.lockInput(this, false);
			var popup:ConfirmationDialogBox = addChildGroup(new ConfirmationDialogBox(success?1:2,message)) as ConfirmationDialogBox;
			popup.configData(null, null, null, "retry");
			popup.init(content["popupContainer"]);
			popup.confirmClicked.add(saveComplete);
			popup.cancelClicked.add(Command.create(Security.showSettings, SecurityPanel.LOCAL_STORAGE));
		}		
		
		private function convertSceneToData():void // convert scene into the data classes needed to save and reproduce image
		{
			// take pic of image and converto to byteArray
			var rect:Rectangle = border.getBounds(border);
			
			var caption:CaptionData = new CaptionData("I made this and more at www.poptropica.com","CreativeBlock BB");
			
			var image:MovieClip = scene.parent as MovieClip;
			
			image.addChild(caption);
			caption.x = rect.left + rect.width * caption.alignX;
			caption.y = rect.top + rect.height * caption.alignY;
			
			var quality:Number = 1;
			if(boothData.headerData)
			{
				if(boothData.headerData.type == DialogBoxData.DEV)
				{
					quality = DEV_QUALITY;
				}
			}
			else if(PlatformUtils.isDesktop && !PlatformUtils.inBrowser && AppConfig.debug)
			{
				quality = DEV_QUALITY;
			}
			
			picData = createBitmapData(image,quality, rect);
			image.removeChild(caption);
			
			// convert scene into data
			
			var bgData:StickerData = bg.get(StickerData);
			currentLayout = new PhotoBoothSceneData();
			currentLayout.sceneStickers = new Vector.<StickerData>();
			
			var stickerData:StickerData;
			for each (var sticker:Entity in stickers)
			{
				stickerData = sticker.get(StickerData);
				currentLayout.sceneStickers.push(stickerData.duplicate());
			}
			
			if(StickerData(bg.get(StickerData)).asset.tab != null)
			{
				stickerData = bg.get(StickerData);
				currentLayout.bg = stickerData.duplicate();
			}
		}
		
		private function savedToServer(...args):void
		{
			unique = false;//trying to prevent duplicates
			if(boothData.submitPopup != null)
			{
				var popup:ConfirmationDialogBox = addChildGroup(new ConfirmationDialogBox(boothData.submitPopup.numBtns, boothData.submitPopup.text)) as ConfirmationDialogBox;
				
				popup.configData(boothData.submitPopup.asset, boothData.submitPopup.prefix, boothData.submitPopup.confirmText, boothData.submitPopup.cancelText);
				
				popup.init(content["popupContainer"]);
			}
		}
		
		private function savePicToXML(e:Event):void// for us
		{
			var byteArray:ByteArray = new ByteArray();
			byteArray.writeUTFBytes(currentLayout.toXML());
			var file:FileReference = new FileReference();
			file.save(byteArray,fileName + ".xml");
		}
	}
}