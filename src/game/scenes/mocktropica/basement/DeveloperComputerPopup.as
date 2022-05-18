package game.scenes.mocktropica.basement
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.timeline.Timeline;
	import game.components.ui.Button;
	import game.components.ui.ToolTip;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.ui.ToolTipType;
	import game.data.ui.TransitionData;
	import game.scenes.mocktropica.MocktropicaEvents;
	import game.scenes.mocktropica.basement.components.FunctionHolder;
	import game.ui.popup.Popup;
	import game.util.EntityUtils;
	import game.util.TimelineUtils;
	
	public class DeveloperComputerPopup extends Popup
	{
		private var deskButtons:Vector.<String>;
		
		private var timeState:String = "day";
		private var weatherState:String = "sunny";
		private var moodState:String = "grumpy";
		private var _events:MocktropicaEvents = new MocktropicaEvents();
		
		// where in poppy's dialog tree we are in
		private var poppyState:Point;
		
		//private var editorData:String = "day,sunny,grumpy";
		
		//private static const MOCK_SCENE_STATE:String = "mock_scene_state";
		
		public function DeveloperComputerPopup(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function destroy():void
		{
			for each (var id:String in deskButtons) 
			{
				var ent:Entity = getEntityById(id);
				removeEntity(ent);
				ent = null;
			}
			deskButtons.splice(0,deskButtons.length);
			deskButtons = null;
			super.destroy();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.darkenBackground = true;
			super.groupPrefix = "scenes/mocktropica/basement/";
			super.init(container);
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(["developerComputerPopup.swf"]);
		}
		
		// all assets ready
		override public function loaded():void
		{			
			super.screen = super.getAsset("developerComputerPopup.swf",true) as MovieClip;
			// setup the transitions 
			transitionIn = new TransitionData();
			transitionIn.duration = .3;
			transitionIn.startPos = new Point(0, -screen.height);
			// this shortcut method flips the start and end position of the transitionIn
			transitionOut = super.transitionIn.duplicateSwitch();
			// this loads the standard close button
			super.loadCloseButton();			
			deskButtons = new Vector.<String>();
			setupMenuPopups();
			setupButtons();
			super.loaded();
		}
		
		private function setupMenuPopups():void
		{
			makeMenu("IslandError");
			makeMenu("ErrorAlert");
			for (var i:int = 0; i < 4; i++) 
			{
				makeMenu("char"+i);
			}
			for (i = 0; i < 3; i++) 
			{
				makeMenu("photo"+i);
			}
			makeMenu("PasswordPersonal");
			makeMenu("PasswordEmployee");
			makeMenu("IslandEditor");
			makeMenu("poppyMenu");
		}
		
		private function makeMenu(menuId:String):void
		{
			var clip:MovieClip = super.screen.content[menuId] as MovieClip;
			var menu:Entity = EntityUtils.createSpatialEntity(this,clip);
			menu.add(new Id(menuId));
			var display:Display = EntityUtils.getDisplay(menu);
			display.visible = false;
			if(menuId != "IslandEditor"){
				var inter:Interaction = InteractionCreator.addToEntity(menu,[InteractionCreator.CLICK]);
			}
		}
		
		private function setupButtons():void
		{
			// setup scene editor button
			makeButton("islandMakerButton",openEditor,true);
			//poppy
			for (i = 0; i < 19; i++) 
			{
				makeButton("misc"+i,Command.create(showPoppy, i),true);
			}
			// set up gag buttons, 47 total
			for (var i:int = 0; i < 6; i++) 
			{
				makeButton("island"+i,Command.create(desktopButtons, i, "IslandError"),true);
			}
			for (i = 0; i < 5; i++)
			{
				makeButton("corrupt"+i,Command.create(desktopButtons, i, "ErrorAlert"),true);
			}
			for (i = 0; i < 4; i++) 
			{
				makeButton("user"+i,Command.create(desktopButtons, i, "char"+i),true);
			}
			for (i = 0; i < 3; i++) 
			{
				makeButton("pic"+i,Command.create(desktopButtons, i, "photo"+i),true);
			}
			for (i = 0; i < 3; i++) 
			{
				makeButton("personal"+i,Command.create(personalButtons, i, "PasswordPersonal"),true);
			}
			for (i = 0; i < 7; i++) 
			{
				makeButton("pop"+i,Command.create(popButtons, i, "PasswordEmployee"),true);
			}
		}
		
		private function makeButton(clipId:String, func:Function, desktop:Boolean = false):Entity
		{
			var clip:MovieClip = MovieClip(super.screen.content[clipId]);
			var button:Entity = ButtonCreator.createButtonEntity(clip, this, func);
			button.add(new Id(clipId));
			var holder:FunctionHolder = new FunctionHolder();
			holder.func = func;
			button.add(holder);
			button.remove(Button);
			if(desktop){
				deskButtons.push(clipId);
			}
			return button;
		}
		
		// open the island editor
		private function openEditor(...p):void
		{
			shellApi.triggerEvent("click2");
			// stop all the desktop buttons
			pauseDesktop();
			var editor:Entity = getEntityById("IslandEditor");
			editor.get(Display).visible = true;
			// add buttons
			for (var i:int = 0; i < 5; i++) 
			{
				var clip:MovieClip =  MovieClip(super.screen.content.IslandEditor["eButton"+i]);
				var button:Entity = getEntityById("eButton"+i);
				if(!button){ 
					button = ButtonCreator.createButtonEntity( clip, this );
				}
				button.remove(Button);
				button.add(new Id("eButton"+i));
				var inter:Interaction = button.get(Interaction);
				inter = button.get( Interaction );
				inter.click.add(Command.create(editorButtons, i, editor));
			}
			// check events
			loadEditorState();
		}		
		
		private function editorButtons(button:Entity, index:int, editor:Entity):void
		{
			shellApi.triggerEvent("click1");
			switch(index){
				case 0:
					toggleDayTime(button, editor);
					break;
				case 1:
					toggleWeather(button, editor);
					break;
				case 2:
					toggleMood(button, editor);
					break;
				case 3:
					save(button, editor);
					this.close();
					break;
				case 4:
					// reload
					loadEditorState();
					closeMenu(editor);
					break;
			}
		}
		
		private function toggleDayTime(button:Entity, editor:Entity):void
		{
			if(timeState == "day"){
				timeState = "night";
				Timeline(button.get(Timeline)).gotoAndStop(timeState);
			}
			else{
				timeState = "day";
				Timeline(button.get(Timeline)).gotoAndStop(timeState);
			}
		}
		
		private function toggleWeather(button:Entity, editor:Entity):void
		{
			if(weatherState == "sunny"){
				weatherState = "rainy";
				Timeline(button.get(Timeline)).gotoAndStop(weatherState);
			}
			else{
				weatherState = "sunny";
				Timeline(button.get(Timeline)).gotoAndStop(weatherState);
			}
		}
		
		private function toggleMood(button:Entity, editor:Entity):void
		{
			if(moodState == "grumpy"){
				moodState = "happy";
				Timeline(button.get(Timeline)).gotoAndStop(moodState);
			}
			else{
				moodState = "grumpy";
				Timeline(button.get(Timeline)).gotoAndStop(moodState);
			}
		}
		
		private function save(button:Entity, editor:Entity):void
		{
			if(timeState == "night"){
				shellApi.triggerEvent(_events.SET_NIGHT,true);
				shellApi.removeEvent(_events.SET_DAY);
			}else{
				shellApi.triggerEvent(_events.SET_DAY,true);
				shellApi.removeEvent(_events.SET_NIGHT);
			}
			
			if(weatherState == "rainy"){
				shellApi.triggerEvent(_events.SET_RAIN,true);
				shellApi.removeEvent(_events.SET_CLEAR);
			}else{
				shellApi.triggerEvent(_events.SET_CLEAR,true);
				shellApi.removeEvent(_events.SET_RAIN);
			}
			
			if(moodState == "happy"){
				shellApi.triggerEvent(_events.IS_HAPPY,true);
			}else{
				shellApi.removeEvent(_events.IS_HAPPY);
			}
			shellApi.triggerEvent("used_dev_computer",true);
			this.close(false);
		}

		
		private function loadEditorState():void
		{
			if(shellApi.checkEvent(_events.SET_NIGHT)){
				timeState = "night";
				getEntityById("eButton0").get(Timeline).gotoAndStop(timeState);
			}else{
				timeState = "day";
				getEntityById("eButton0").get(Timeline).gotoAndStop(timeState);
			}
			if(shellApi.checkEvent(_events.SET_RAIN)){
				weatherState = "rainy";
				getEntityById("eButton1").get(Timeline).gotoAndStop(weatherState);
			}else{
				weatherState = "sunny";
				getEntityById("eButton1").get(Timeline).gotoAndStop(weatherState);
			}
			if(shellApi.checkEvent(_events.IS_HAPPY)){
				moodState = "happy";
				getEntityById("eButton2").get(Timeline).gotoAndStop(moodState);
			}else{
				moodState = "grumpy";
				getEntityById("eButton2").get(Timeline).gotoAndStop(moodState);
			}
		}
		
		private function showPoppy(icon:Entity, index:int):void
		{
			// poppy q&a tree
			pauseDesktop();
			// show menu clip
			var poppyMenu:Entity = getEntityById("poppyMenu");
			poppyMenu.get(Display).visible = true;
			poppyState = new Point(0,1);
			trace(poppyState.toString());
			// prep questions & answers
			var answers:Entity = getEntityById("answers");
			if(!answers){
				answers = TimelineUtils.convertClip(screen.content.poppyMenu.menu["answers"],this,null,null,false);
				answers.add(new Id("answers"));
			}
			// prep character
			var poppy:Entity = getEntityById("poppy");
			if(!poppy){
				poppy = EntityUtils.createSpatialEntity(this,screen.content.poppyMenu["poppy"]);
				poppy = TimelineUtils.convertClip(screen.content.poppyMenu["poppy"],this,poppy,null,false);
				poppy.add(new Id("poppy"));
			}
			var inter:Interaction = InteractionCreator.addToEntity(poppy,[InteractionCreator.CLICK]);
			inter.click.addOnce(Command.create(closePoppy, poppyMenu));
			ToolTipCreator.addUIRollover(poppy,ToolTipType.CLICK);
			//exit button
			var exit:Entity = getEntityById("exit");
			if(!exit){
				exit = EntityUtils.createSpatialEntity(this,screen.content.poppyMenu.menu["answers"]["exit"]);
				exit.add(new Id("exit"));
			}
			var exitInter:Interaction = InteractionCreator.addToEntity(exit,[InteractionCreator.CLICK]);
			exitInter.click.addOnce(Command.create(closePoppy, poppyMenu));
			ToolTipCreator.addUIRollover(exit,ToolTipType.CLICK);
			// add radial looking buttons
			for (var i:int = 0; i < 3; i++) 
			{
				var clip:MovieClip =  MovieClip(screen.content.poppyMenu.menu["radial"+i]);
				var button:Entity = getEntityById("radial"+i);
				if(!button){ 
					button = ButtonCreator.createButtonEntity( clip, this );
				}
				button.remove(Button);
				button.add(new Id("radial"+i));
				var buttonInter:Interaction = button.get(Interaction);
				buttonInter = button.get( Interaction );
				buttonInter.click.add(Command.create(poppyButtons, i, poppyMenu));
			}
			shellApi.triggerEvent("click2");
		}
		
		// handle advancing the answer trees
		private function poppyButtons(button:Entity, index:int, poppyMenu:Entity):void
		{
			// answers always advance to the next group of 3 questions
			poppyState.x+=1;
			poppyState.y=index+1;
			var answers:Entity = getEntityById("answers");
			var poppy:Entity = getEntityById("poppy");
			if(poppyState.x > 2){
				hideEnt("radial0");
				hideEnt("radial1");
				hideEnt("radial2");
			}
			answers.get(Timeline).gotoAndStop("a"+poppyState.x.toString()+poppyState.y.toString());
			poppy.get(Timeline).gotoAndStop("pose"+poppyState.x.toString());
			shellApi.triggerEvent("click1");
		}
		
		private function hideEnt(id:String):void{
			var ent:Entity = getEntityById(id);
			ent.get(Display).visible = false;
			ent.remove(ToolTip);
		}
		
		private function closePoppy(button:Entity, menu:Entity):void
		{
			var display:Display = menu.get(Display);
			display.visible = false;
			button.remove(ToolTip);
			var inter:Interaction = Interaction(button.get(Interaction));
			if(inter){
				inter.click.removeAll();
			}
			pauseDesktop(false);
			shellApi.triggerEvent("click1");
		}
		
		private function desktopButtons(button:Entity, index:int, menuId:String):void
		{
			pauseDesktop();
			openMenu(button,menuId);
			shellApi.triggerEvent("click2");
			if(menuId.search("photo") == -1 && menuId.search("char") == -1){
				shellApi.triggerEvent("alert");
			}
		}
		
		private function personalButtons(button:Entity, index:int, menuId:String):void
		{
			pauseDesktop();
			openMenu(button,menuId);
			shellApi.triggerEvent("click2");
			shellApi.triggerEvent("alert");
		}
		
		private function popButtons(button:Entity, index:int, menuId:String):void
		{
			pauseDesktop();
			openMenu(button,menuId);
			shellApi.triggerEvent("click2");
			shellApi.triggerEvent("alert");
		}
		
		// hide interactions and tooltips
		private function pauseDesktop(paused:Boolean = true):void
		{
			for (var i:int = 0; i < deskButtons.length; i++) 
			{
				var but:Entity = getEntityById(deskButtons[i]);
				var inter:Interaction = Interaction(but.get(Interaction));
				if(paused){
					but.remove(ToolTip);
					inter.click.removeAll();
				}
				else{
					ToolTipCreator.addUIRollover(but,ToolTipType.CLICK);
					inter.click.add(but.get(FunctionHolder).func);
				}
			}
		}
		
		private function openMenu(button:Entity, menuId:String):void
		{
			// stop all the desktop buttons
			pauseDesktop();
			var menu:Entity = getEntityById(menuId);
			var display:Display = menu.get(Display);	
			var inter:Interaction = menu.get(Interaction);
			display.visible = true;
			inter.click.addOnce(Command.create(closeMenu));
			ToolTipCreator.addUIRollover(menu,ToolTipType.CLICK);
		}
		
		// click to close menus
		private function closeMenu(menu:Entity):void
		{
			var display:Display = menu.get(Display);
			display.visible = false;
			menu.remove(ToolTip);
			var inter:Interaction = Interaction(menu.get(Interaction));
			if(inter){
				inter.click.removeAll();
			}
			pauseDesktop(false);
			shellApi.triggerEvent("click1");
		}
	};
};