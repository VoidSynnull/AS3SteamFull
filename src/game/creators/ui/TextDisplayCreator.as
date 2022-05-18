package game.creators.ui
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.components.entity.Sleep;
	import game.components.ui.TextDisplay;
	import game.systems.SystemPriorities;
	import game.systems.ui.TextDisplaySystem;

	
	public class TextDisplayCreator
	{		
		public static function createInputText( group:Group, container:DisplayObjectContainer, text:String = "", textFormat:TextFormat = null, x:Number = 0, y:Number = 0, autoSize:String = TextFieldAutoSize.NONE):Entity
		{			
			var entity:Entity = new Entity();
			
			// create spatial
			var spatial:Spatial = new Spatial();
			var scaleFactor:Number = 1.5; // TO DO: Change size based on device. //Capabilities.screenDPI / 72
			spatial.scaleX = spatial.scaleY = scaleFactor

			spatial.x = x;
			spatial.y = y;
			
			//create display
			var display:Display = new Display( new MovieClip(), container );
			
			// create textDisplay
			var textDisplay:TextDisplay = new TextDisplay();
			display.displayObject.addChild(textDisplay.tf);
			if ( textFormat == null )
			{
				textDisplay.tf.defaultTextFormat = new TextFormat("CreativeBlock BB", 14, 0xD5E1FF);
			}
			else
			{
				textDisplay.tf.defaultTextFormat = textFormat;
			}
			
			textDisplay.tf.embedFonts = true;
			textDisplay.tf.type = TextFieldType.DYNAMIC;
			textDisplay.tf.selectable = false;
			textDisplay.tf.autoSize = autoSize;
			textDisplay.tf.wordWrap = true;
			textDisplay.tf.multiline = true;
			textDisplay.queue += text;
			
			entity.add(new Sleep());
			entity.add(display);			
			entity.add(spatial);
			entity.add(textDisplay);
			
			group.addSystem( new TextDisplaySystem, SystemPriorities.update );
			group.addEntity( entity );
			return entity;
		}	
		
		public static function create( group:Group, container:DisplayObjectContainer, text:String = "", textFormat:TextFormat = null, x:Number = 0, y:Number = 0, autoSize:String = TextFieldAutoSize.NONE):Entity
		{			
			var entity:Entity = new Entity();
			
			// create spatial
			var spatial:Spatial = new Spatial();
			var scaleFactor:Number = 1.5; // TO DO: Change size based on device. //Capabilities.screenDPI / 72
			spatial.scaleX = spatial.scaleY = scaleFactor
			
			spatial.x = x;
			spatial.y = y;
			
			//create display
			var display : Display = new Display( new MovieClip(), container);
			MovieClip(display.displayObject).mouseEnabled = false;
			MovieClip(display.displayObject).mouseChildren = false;
			
			// create textDisplay
			var textDisplay:TextDisplay = new TextDisplay();
			display.displayObject.addChild(textDisplay.tf);
			if ( textFormat == null )
			{
				textDisplay.tf.defaultTextFormat = new TextFormat("CreativeBlock BB", 14, 0xD5E1FF);
			}
			else
			{
				textDisplay.tf.defaultTextFormat = textFormat;
			}
			
			textDisplay.tf.embedFonts = true;
			textDisplay.tf.type = TextFieldType.DYNAMIC;
			textDisplay.tf.selectable = false;
			textDisplay.tf.autoSize = autoSize;
			textDisplay.tf.wordWrap = true;
			textDisplay.tf.multiline = true;
			textDisplay.queue += text;
			
			entity.add(new Sleep());
			entity.add(display);			
			entity.add(spatial);
			entity.add(textDisplay);
			
			group.addSystem( new TextDisplaySystem, SystemPriorities.update );
			group.addEntity( entity );
			return entity;
		}	
		
	};
};
