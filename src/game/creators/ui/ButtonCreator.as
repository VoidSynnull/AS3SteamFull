package game.creators.ui
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.DisplayGroup;
	import engine.group.Group;
	import engine.util.Command;
	
	import game.components.timeline.Timeline;
	import game.components.ui.Button;
	import game.creators.entity.BitmapTimelineCreator;
	import game.data.ui.ButtonSpec;
	import game.data.ui.ToolTipType;
	import game.systems.timeline.BitmapSequenceSystem;
	import game.systems.ui.ButtonSystem;
	import game.ui.elements.BasicButton;
	import game.ui.elements.MultiStateButton;
	import game.ui.elements.MultiStateToggleButton;
	import game.ui.elements.StandardButton;
	import game.util.DataUtils;
	import game.util.DisplayPositionUtils;
	import game.util.DisplayPositions;
	import game.util.EntityUtils;
	import game.util.TimelineUtils;
	
	import org.osflash.signals.Signal;
	import org.osflash.signals.natives.NativeSignal;
	
	public class ButtonCreator
	{	
		
		/**
		 * Creates a non-entity button that not support button states.
		 * @param	displayObject
		 * @param	interactions
		 * @param	parent
		 * @param	handler - function called for first interaction in array, passes BasicButton
		 * @return
		 */
		public static function createBasicButton(displayObject:DisplayObjectContainer, interactions:Array = null, parent:Group = null, handler:Function = null):BasicButton
		{
			var button:BasicButton = new BasicButton();
			
			button.displayObject = displayObject;	
			button.displayObject.mouseEnabled = true;
			
			if ( !interactions )
			{
				interactions = [ InteractionCreator.CLICK ];
			}
			
			InteractionCreator.addToUIElement(button, interactions);
			
			if( parent != null )
			{
				parent.addElement(button);
			}
			
			if ( handler != null )
			{
				var event:String = interactions[0];
				var signal:NativeSignal = button[ event ] as NativeSignal;
				signal.add( Command.create( handler, button ) );
			}
			
			return(button);
		}
		
		/**
		 * Creates a non-entity button that support standard button states, does not support disabled
		 * @param displayObject
		 * @param handler
		 * @param container
		 * @param group
		 * @param interactions
		 * @return 
		 */
		public static function createStandardButton( displayObject:DisplayObjectContainer, handler:Function = null, container:DisplayObjectContainer = null, group:Group = null, interactions:Array  = null ):StandardButton
		{
			var button:StandardButton = new StandardButton();
			button.displayObject = displayObject;
			button.displayObject.mouseEnabled = true;
			if (null != container) {
				container.addChild( displayObject );
			}
			ButtonCreator.configureButton(button, group, handler, interactions);
			return button;
		}
		public static function createNewStandardButton(clip:MovieClip, group:Group, click:Function=null, overState:Function=null, outState:Function=null, id:String=""):Entity {
			var entity:Entity = EntityUtils.createSpatialEntity(group,clip);
			TimelineUtils.convertClip(clip,group,entity,null,false);
			InteractionCreator.addToEntity(entity, [InteractionCreator.CLICK, InteractionCreator.OVER, InteractionCreator.OUT, InteractionCreator.TOUCH]);
			if(click != null) {
				entity.get(Interaction).click.add(click);
			}
			if(overState != null) {
				entity.get(Interaction).over.add(overState);
			}
			if(outState != null) {
				entity.get(Interaction).out.add(outState);
			}
			ToolTipCreator.addUIRollover(entity, ToolTipType.CLICK);
			entity.add(new Id(id));
			return entity;
		}
		/**
		 * Creates a non-entity button that support standard button states as well as a disabled state
		 * @param displayObject
		 * @param clickHandler
		 * @param container
		 * @param group
		 * @param interactions
		 * @return 
		 */
		public static function createMultiStateButton(displayObject:DisplayObjectContainer, clickHandler:Function=null, container:DisplayObjectContainer=null, group:Group=null, interactions:Array=null):MultiStateButton 
		{
			var button:MultiStateButton = new MultiStateButton(displayObject as MovieClip);
			button.displayObject = displayObject;
			button.displayObject.mouseEnabled = true;
			if (null != container) {
				container.addChild(displayObject);
			}
			ButtonCreator.configureButton(button, group, clickHandler, interactions);
			return button;
		}
		
		/**
		 * Creates a non-entity button that support standard & selected button states
		 * @param displayObject
		 * @param clickHandler
		 * @param container
		 * @param group
		 * @param interactions
		 * @return 
		 * 
		 */
		public static function createMultiStateToggleButton(displayObject:DisplayObjectContainer, clickHandler:Function=null, container:DisplayObjectContainer=null, group:Group=null, interactions:Array=null):MultiStateToggleButton 
		{
			var button:MultiStateToggleButton = new MultiStateToggleButton(displayObject as MovieClip);
			button.displayObject = displayObject;
			displayObject.mouseEnabled = true;
			if (null != container) {
				container.addChild(displayObject);
			}
			ButtonCreator.configureButton(button, group, clickHandler, interactions);
			return button;
		}
		
		private static function configureButton(button:StandardButton, group:Group = null, clickHandler:Function = null, interactions:Array = null):void 
		{
			if (button.displayObject) button.displayObject.mouseChildren = false;
			if (null != group) {
				group.addElement(button);
			}
			ButtonCreator.createButtonInteraction(button, interactions);
			if (null != clickHandler) {
				button.click.add(clickHandler);
			}
		}
		
		/**
		 * Creates <code>loadStandardButton()</code> from an external asset, setups up button using spec once loaded.
		 */
		public static function loadStandardButton( path:String, group:Group, btnSpec:ButtonSpec, loadHandler:Function = null ):StandardButton
		{
			var button:StandardButton = new StandardButton();
			group.shellApi.loadFile( group.shellApi.assetPrefix + path, ButtonCreator.onStandardButtonLoaded, button, btnSpec, loadHandler );
			group.addElement(button);
			
			return button;
		}
		
		public static function onStandardButtonLoaded( displayObject:DisplayObjectContainer, button:StandardButton, btnSpec:ButtonSpec, loadHandler:Function = null ):void
		{
			button.displayObject = ( MovieClip(displayObject)["content"] ) ? MovieClip(displayObject).content : displayObject;
			button.displayObject.mouseEnabled = true;
			if (btnSpec.container) {
				btnSpec.container.addChild(button.displayObject);
			}
			if (btnSpec.position) {
				button.setPosition(btnSpec.position.x, btnSpec.position.y);
			}
			
			ButtonCreator.createButtonInteraction( button, btnSpec.interactions );
			if (btnSpec.clickHandler != null) 
			{
				if (button.click && !button.up) {	// some buttons only handle up, some handle only click
					button.click.add(btnSpec.clickHandler);
				}
				if (button.up) {
					button.up.add( btnSpec.clickHandler );
				}
			}
			if (btnSpec.pressAction != null) {
				BasicButton.addPressAction(button, btnSpec.pressAction);
			}
			
			if( loadHandler != null ) { loadHandler(); }
		}
		
		/**
		 * Similar to <code>loadStandardButton()</code>, this method initiates the loading of a disk asset
		 * which will be attached to a <code>MultiStateButton</code> when loading is complete. The supplied
		 * <code>ButtonSpec</code> will be used to configure the button at that time. 
		 * @param path	A <code>String</code> specifying the asset's location
		 * @param btnSpec	Configuration data to be applied when the asset is fully loaded
		 * @return	A raw <code>MultiStateButton</code>, with mostly empty properties. How can you know when it is safe to use? Only way I can think of is to check its <code>displayObject</code> property.
		 * @see game.data.ui.ButtonSpec
		 * @see game.ui.elements.MultiStateButton
		 */		
		public static function loadMultiStateButton(path:String, btnSpec:ButtonSpec):MultiStateButton 
		{
			var button:MultiStateButton = new MultiStateButton();
			btnSpec.parentGroup.shellApi.loadFile(btnSpec.parentGroup.shellApi.assetPrefix + path, ButtonCreator.onMultiStateButtonLoaded, button, btnSpec);
			btnSpec.parentGroup.addElement(button);
			
			return button;
		}
		
		private static function onMultiStateButtonLoaded(swf:MovieClip, button:MultiStateButton, btnSpec:ButtonSpec):void 
		{
			button.displayObject = swf.content;
			button.displayObject.mouseEnabled = true;
			button.faces = swf.content;
			if (btnSpec.container) {
				btnSpec.container.addChild(swf);
			}
			if (btnSpec.position) {
				button.setPosition(btnSpec.position.x, btnSpec.position.y);
			}
			ButtonCreator.createButtonInteraction(button, btnSpec.interactions);
			if (btnSpec.clickHandler != null) {
				button.click.add(btnSpec.clickHandler);
			}
			if (btnSpec.pressAction != null) {
				BasicButton.addPressAction(button, btnSpec.pressAction);
			}
		}
		
		/**
		 * Loads and sets the default close button from the shared asset.
		 * @param group
		 * @param container
		 * @param handler
		 * @param displayPosition - String defining position, refer to DisplayPositions for valid types
		 * @param xPadding
		 * @param yPadding
		 * @param viewportRelative
		 * @param onLoadHandler
		 * @return 
		 */
		public static function loadCloseButton( group:DisplayGroup, container:DisplayObjectContainer = null, handler:Function = null, displayPosition:String = "", xPadding:int = 50, yPadding:int = 50, viewportRelative:Boolean = true, onLoadHandler:Function = null ): Entity 
		{
			var buttonSpec:ButtonSpec = new ButtonSpec();
			if( displayPosition == "" )	{ displayPosition = DisplayPositions.TOP_RIGHT; }
			if( viewportRelative )
			{
				buttonSpec.position = DisplayPositionUtils.getPosition( displayPosition, group.shellApi.viewportWidth, group.shellApi.viewportHeight, xPadding, yPadding);
			}
			else
			{
				buttonSpec.position = DisplayPositionUtils.getPosition( displayPosition, container.width, container.height, xPadding, yPadding);
			}
			buttonSpec.clickHandler = handler;
			buttonSpec.container = container;
			
			//return ButtonCreator.loadStandardButton( ButtonCreator.CLOSE_BUTTON, group, buttonSpec, onLoadHandler );
			return ButtonCreator.loadButtonEntityFromSpec( ButtonCreator.CLOSE_BUTTON, group, buttonSpec, onLoadHandler );
		}
		
		/**
		 * Creates an Entity that functions as a button.
		 * @param displayObject
		 * @param group
		 * @param handler
		 * @param container
		 * @param interactions
		 * @param cursorType - cursor type displayed on roll over 
		 * @param isStatic - default is true, when true button positioning is not paired to Spatial
		 * @return 
		 * 
		 */
		public static function createButtonEntity( displayObject:DisplayObjectContainer, group:Group, handler:Function = null, container:DisplayObjectContainer = null, interactions:Array = null, cursorType:String = null, isStatic:Boolean = true, bitmap:Boolean = false, oversampleScale:Number = 1 ):Entity
		{
			var entity:Entity = new Entity();
			ButtonCreator.assignButtonEntity( entity, displayObject, group, handler, container, interactions, cursorType, isStatic, bitmap, oversampleScale );
			
			group.addEntity(entity);
			group.addSystem( new ButtonSystem() );
			
			return entity;
		}
		
		/**
		 * Create button Entity in case where the asset to be used still requires loading.
		 * @param assetPath
		 * @param group
		 * @param handler
		 * @param container
		 * @param interactions
		 * @param loadHandler
		 * @param cursorType
		 * @param isStatic
		 * @param bitmap
		 * @param oversampleScale
		 * @return 
		 */
		public static function loadButtonEntity( assetPath:String, group:Group, handler:Function = null, container:DisplayObjectContainer = null, interactions:Array = null, loadHandler:Function = null, cursorType:String = null, isStatic:Boolean = true, bitmap:Boolean = false, oversampleScale:Number = 1 ):Entity
		{
			var entity:Entity = new Entity();
			
			var btnSpec:ButtonSpec = new ButtonSpec();
			btnSpec.clickHandler = handler;
			btnSpec.container = container;
			btnSpec.interactions = interactions;
			btnSpec.cursorType = cursorType;
			btnSpec.isStatic = isStatic;
			btnSpec.bitmap = bitmap;
			btnSpec.bitmapScale = oversampleScale;
			
			return ButtonCreator.loadButtonEntityFromSpec( assetPath, group, btnSpec, loadHandler );
		}
		
		public static function loadButtonEntityFromSpec( assetPath:String, group:Group, btnSpec:ButtonSpec, loadHandler:Function = null ):Entity
		{
			var entity:Entity = new Entity();
			group.shellApi.loadFile( group.shellApi.assetPrefix + assetPath, ButtonCreator.onButtonEntityLoaded, entity, group, btnSpec, loadHandler );
			
			group.addEntity(entity);
			group.addSystem( new ButtonSystem() );
			
			return entity;
		}
		
		private static function onButtonEntityLoaded( displayObject:DisplayObjectContainer, entity:Entity, group:Group, spec:ButtonSpec, loadHandler:Function = null ):void
		{
			// search for 'content' instance name, this should be used as the displayObject if found
			if( displayObject.hasOwnProperty("content") )
			{
				displayObject = MovieClip(displayObject).content
			}
			spec.displayObject = displayObject;
			
			// assign position coordinates if passed (might need to look into this further if we want these to align with Spatial)
			if( spec.position != null )
			{
				displayObject.x = spec.position.x;
				displayObject.y = spec.position.y;
			}
			
			createButtonEntityFromSpec( spec, group, entity ); 
			if( loadHandler != null )
			{
				loadHandler( entity );
			}
		}
		
		/**
		 * Creates an Entity that functions as a button from a ButtonSpec. 
		 * @param spec
		 * @param group
		 * @return 
		 */
		public static function createButtonEntityFromSpec( spec:ButtonSpec, group:Group, entity:Entity = null ):Entity
		{
			if( entity )
			{
				assignButtonEntity(  entity, spec.displayObject, group, spec.clickHandler, spec.container, spec.interactions, spec.cursorType, spec.isStatic, spec.bitmap, spec.bitmapScale);
			}
			else
			{
				entity = createButtonEntity(  spec.displayObject, group, spec.clickHandler, spec.container, spec.interactions, spec.cursorType, spec.isStatic, spec.bitmap, spec.bitmapScale);
			}
			return entity
		}
		
		public static function assignButtonEntity( entity:Entity, displayObject:DisplayObjectContainer, group:Group = null, handler:Function = null, container:DisplayObjectContainer = null, interactions:Array  = null, cursorType:String = null, isStatic:Boolean = true, bitmap:Boolean = false, oversampleScale:Number = 1):Entity
		{
			// create Display
			var display:Display = entity.get(Display);
			if( !display )
			{
				display = new Display( displayObject, container );
				entity.add( display );
			}
			display.isStatic = isStatic;
			
			// create Spatial
			// TODO :: isStatic if true do we need a Spatial?  Necessity of RenderSystem, might want to rethink that. -bard
			if( !entity.has(Spatial) )
			{
				entity.add( new Spatial() );
			}
			
			// create timeline components
			if( !bitmap )
			{
				TimelineUtils.convertClip( MovieClip(displayObject), group, entity );
			}
			else
			{
				BitmapTimelineCreator.convertToBitmapTimeline( entity, null, true, null, oversampleScale );
				if( group )	{ group.addSystem( new BitmapSequenceSystem() ); }
			}
			Timeline(entity.get(Timeline)).playing = false;
			display.displayObject.mouseEnabled = true;
			
			// create Interaction, NOTE : Interaction must be added after bitmap operation
			if ( !interactions )
			{
				interactions = [ InteractionCreator.UP, InteractionCreator.OVER, InteractionCreator.DOWN, InteractionCreator.OUT, InteractionCreator.CLICK ];
			}
			var interaction:Interaction;
			//var hitClip:DisplayObjectContainer = MovieClip(display.displayObject).hit;
			if( MovieClip(displayObject).hit )
			{
				interaction = InteractionCreator.addToEntity(entity, interactions, MovieClip(displayObject).hit );
			}
			else
			{
				interaction = InteractionCreator.addToEntity(entity, interactions, display.displayObject );
				display.displayObject.mouseChildren = false;
			}
			
			// create Button component
			var button:Button = new Button();
			entity.add( button );
			var state:String;
			var i:int = 0;
			for (i; i < interactions.length; i++)
			{
				state = interactions[i];
				Signal(interaction[state]).add( button[state + "Handler"] );
			}
			
			if ( handler != null )
			{
				interaction.click.add( handler );	// TODO :: needs to signal at end of button timeline
			}
			
			cursorType = ( !DataUtils.validString(cursorType) ) ? ToolTipType.CLICK : cursorType;
			if( cursorType != ToolTipType.NONE )
			{
				ToolTipCreator.addUIRollover(entity, cursorType);
			}
			
			if( group ) { group.addSystem( new ButtonSystem() ); }
			
			return entity;
		}
		
		public static function createButtonInteraction( button:StandardButton, interactions:Array = null ):void
		{
			if ( !interactions )
			{
				interactions = [InteractionCreator.CLICK, InteractionCreator.UP, InteractionCreator.OVER, InteractionCreator.DOWN, InteractionCreator.OUT ];
			}
			InteractionCreator.addToUIElement(button, interactions);
			
			// sync button
			var state:String;
			var signal:NativeSignal;
			var i:int = 0;
			for (i; i < interactions.length; i++)
			{
				state = interactions[i];
				signal = button[state];
				signal.add( button[state + "Handler"]);
			}
			
			button.state = StandardButton.UP;
		}
		
		public static function addLabel(displayObject:DisplayObjectContainer, label:String, labelFormat:TextFormat = null, orient:String = ""):TextField
		{
			var text:TextField = new TextField();
			text.embedFonts = true
			text.antiAliasType = AntiAliasType.NORMAL;
			text.text = label;
			//text.background = true;
			
			labelFormat = ( labelFormat ) ? labelFormat : FONT_DEFAULT;
			text.setTextFormat(labelFormat);
			
			text.autoSize = TextFieldAutoSize.CENTER;
			
			orient = ( orient == "" ) ? ButtonCreator.ORIENT_TOPLEFT : orient;
			
			text.x = 0;
			text.y = 0;
			
			if ( orient == ButtonCreator.ORIENT_TOPLEFT )
			{
				var deltaX:Number = displayObject.width / displayObject.scaleX - text.width;
				var deltaY:Number = displayObject.height / displayObject.scaleY - text.height;
				
				text.x = deltaX * .5;
				text.y = deltaY * .5;
			}
			else if ( orient == ButtonCreator.ORIENT_CENTERED )
			{
				text.x -= text.width * .5;
				text.y -= text.height * .5;
			}
			else if(orient == ButtonCreator.ORIENT_BOTTOM_CENTERED)
			{
				text.x -= text.width * .5;
				text.y = (displayObject.height / displayObject.scaleY) *.5;				
			}
			
			text.mouseEnabled = false;
			
			displayObject.addChild(text);
			return text;
		}
		
		public static const FONT_DEFAULT:TextFormat = new TextFormat("CreativeBlock BB", 20, 0xD5E1FF);
		
		public static const ORIENT_CENTERED:String = "centered";
		public static const ORIENT_TOPLEFT:String = "topLeft";
		public static const ORIENT_BOTTOM_CENTERED:String = "bottom_centered";
		
		public static const BACK_BUTTON:String = "ui/general/backButton.swf";
		public static const CLOSE_BUTTON:String = "ui/general/closeButton.swf";
	}
}
