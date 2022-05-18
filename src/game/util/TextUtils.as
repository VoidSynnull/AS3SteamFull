package game.util
{
	import flash.display.BlendMode;
	import flash.display.DisplayObjectContainer;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import game.data.text.TextData;
	import game.data.text.TextStyleData;

	/**
	 * Utilities for managing TextFields 
	 * @author umckiba
	 * 
	 */
	public class TextUtils
	{
		public static function convertText( tf:TextField, newFormat:TextFormat, message:String = "" ):TextField
		{
			var newTextField:TextField = TextUtils.refreshText( tf ); 
			newTextField.embedFonts = true;
			newTextField.defaultTextFormat = newFormat;
			if ( !DataUtils.validString(message) )
				message = "";
			newTextField.text = ( message != "" ) ? message : tf.text;
			
			return newTextField;
		}
		
		/**
		 * Replace the TextField with a dynamically created TextField.
		 * NOTE :: Be sure to update any references to the original TextField to the TextField that is passed back by this method.
		 * Creating a TextField within the code mitigates the issues working with a TextField contained within a swf on import.
		 */
		public static function refreshText( tf:TextField, font:String = "" ):TextField
		{
			if( tf )
			{
				var newTextField:TextField = cloneTextField( tf, font );
				// swap the display
				DisplayUtils.swap( newTextField, tf );
	
				return newTextField;
			}
			trace( "TextUtils :: WARNING :: refreshText() : TextField given was null" );
			return tf;
		}
		
		/**
		 * Returns a duplicate of the given TextField given, applying all aspects of the original Textfield to the duplicate 
		 * @param tf
		 * @param font - Optional Font id to apply to clone
		 * @return 
		 */
		public static function cloneTextField(oldTextField:TextField, font:String = ""):TextField
		{
			var newTextField:TextField 			= new TextField();
			newTextField.alpha 					= oldTextField.alpha;
			newTextField.alwaysShowSelection 	= oldTextField.alwaysShowSelection;
			newTextField.antiAliasType 			= oldTextField.antiAliasType;
			newTextField.autoSize 				= oldTextField.autoSize;
			newTextField.background 			= oldTextField.background;
			newTextField.backgroundColor 		= oldTextField.backgroundColor;
			newTextField.border 				= oldTextField.border;
			newTextField.borderColor 			= oldTextField.borderColor;
			newTextField.condenseWhite 			= oldTextField.condenseWhite;
			newTextField.displayAsPassword 		= oldTextField.displayAsPassword;
			newTextField.embedFonts 			= true; //Setting ot true by default. All fonts for Poptropica should be installed/embedded.
			newTextField.filters				= oldTextField.filters;
			newTextField.gridFitType 			= oldTextField.gridFitType;
			newTextField.height 				= oldTextField.height;
			newTextField.htmlText 				= oldTextField.htmlText;
			newTextField.mask					= oldTextField.mask;
			newTextField.maxChars 				= oldTextField.maxChars;
			newTextField.mouseEnabled 			= oldTextField.mouseEnabled;
			newTextField.mouseWheelEnabled		= oldTextField.mouseWheelEnabled;
			newTextField.multiline 				= oldTextField.multiline;
			newTextField.name					= oldTextField.name;
			newTextField.restrict 				= oldTextField.restrict;
			newTextField.rotation 				= oldTextField.rotation;
			newTextField.scrollH 				= oldTextField.scrollH;
			newTextField.scrollRect 			= oldTextField.scrollRect;
			newTextField.scrollV 				= oldTextField.scrollV;
			newTextField.selectable 			= oldTextField.selectable;
			newTextField.sharpness 				= oldTextField.sharpness;
			newTextField.styleSheet 			= oldTextField.styleSheet;
			newTextField.text 					= oldTextField.text;
			newTextField.textColor 				= oldTextField.textColor;
			newTextField.thickness 				= oldTextField.thickness;
			newTextField.transform				= oldTextField.transform;
			newTextField.type 					= oldTextField.type;
			newTextField.useRichTextClipboard 	= oldTextField.useRichTextClipboard;
			newTextField.visible				= oldTextField.visible;
			newTextField.width 					= oldTextField.width;
			newTextField.wordWrap 				= oldTextField.wordWrap;
			newTextField.x 						= oldTextField.x;
			newTextField.y 						= oldTextField.y;
			
			var oldTextFormat:TextFormat = oldTextField.defaultTextFormat;
			var newTextFormat:TextFormat = TextUtils.cloneTextFormat(oldTextFormat);
			
			if(font)
			{
				newTextFormat.font = font;
			}
			
			newTextField.setTextFormat(newTextFormat);
			newTextField.defaultTextFormat = newTextFormat;
			
			return newTextField;
		}
		
		public static function cloneTextFormat(oldTextFormat:TextFormat):TextFormat
		{
			var newTextFormat:TextFormat 	= new TextFormat();
			newTextFormat.align 			= oldTextFormat.align;
			newTextFormat.blockIndent 		= oldTextFormat.blockIndent;
			newTextFormat.bold 				= oldTextFormat.bold;
			newTextFormat.bullet 			= oldTextFormat.bullet;
			newTextFormat.color 			= oldTextFormat.color;
			newTextFormat.font 				= oldTextFormat.font;
			newTextFormat.indent 			= oldTextFormat.indent;
			newTextFormat.italic 			= oldTextFormat.italic;
			newTextFormat.kerning 			= oldTextFormat.kerning;
			newTextFormat.leading 			= oldTextFormat.leading;
			newTextFormat.leftMargin 		= oldTextFormat.leftMargin;
			newTextFormat.letterSpacing 	= oldTextFormat.letterSpacing;
			newTextFormat.rightMargin 		= oldTextFormat.rightMargin;
			newTextFormat.size 				= oldTextFormat.size;
			newTextFormat.tabStops 			= oldTextFormat.tabStops;
			newTextFormat.target 			= oldTextFormat.target;
			newTextFormat.underline 		= oldTextFormat.underline;
			newTextFormat.url 				= oldTextFormat.url;
			
			return newTextFormat;
		}
		
		/**
		 * Adds a 'shadow' to the given textfield by creating a duplciate textfield.
		 * Does not use a filter but rather creates a duplicate Textfield that is offset and layered below original text
		 * @param tf
		 * @param alpha - alpha of shadow textfield
		 * @param color - color of shadow textfield
		 * @param offsetX - x offset of shadow textfield
		 * @param offsetY - y offset of shadow textfield
		 * @return - returns the 'shadow' textfield
		 */
		public static function addShadow( tf:TextField, alpha:Number = .15, color:Number = 0x000000, offsetX:Number = -1, offsetY:Number = 2 ):TextField
		{
			var shadowTF:TextField = TextUtils.cloneTextField( tf );
			
			var parent:DisplayObjectContainer = tf.parent;
			
			if( parent )
			{
				var index:int = parent.getChildIndex( tf );
				parent.addChildAt( shadowTF, index );
			}
			
			shadowTF.textColor = color;
			shadowTF.defaultTextFormat.color = color;
			shadowTF.x += offsetX;
			shadowTF.y += offsetY;
			shadowTF.blendMode = BlendMode.LAYER;
			shadowTF.embedFonts = true;
			shadowTF.alpha = alpha;
			shadowTF.selectable = false;
			shadowTF.mouseEnabled = false;
			
			return shadowTF;
		}
		
		/**
		 * Call after text has been positioned, otherwise positioning will negate alignment.
		 */
		public static function verticalAlignTextField( tf: TextField ): void 
		{
			tf.y += Math.round((tf.height - tf.textHeight) / 2);
		}

		/**
		 * Creates a block of text with a max width.
		 * The goal is to divide the dialog into lines that are approximately equal in length, creating a nice block dialog with no "orphaned" text on the last line.
		 * created by Jordan - 6/12/12
		 */
		public static function formatAsBlock(dialogText:String, maxLineLength:Number = 30):String 
		{
			var numLines:uint = Math.ceil(dialogText.length/maxLineLength);
			var targetLineLength:uint = Math.floor(dialogText.length/numLines);
			var parsedDialogText:String = "";
			var linePosition:uint = 0;
			var curChar:String;
			
			for (var i:uint=0; i<dialogText.length; i++) 
			{
				curChar = dialogText.charAt(i);
				linePosition ++;
				
				if (linePosition >= targetLineLength && curChar == " ") 
				{
					linePosition = 0;
					curChar = "\n";
				}
				else if (linePosition >= targetLineLength && curChar == "-") 
				{
					linePosition = 0;
					curChar = "-\n";
				}
				
				parsedDialogText += curChar;
			}

			return(parsedDialogText);
		}
		
		/**
		 * Apply TextStyleData to TextField.
		 * TextStyleData are accessed throught the TextManager
		 * @param TextStyleData
		 * @param textfield
		 */
		public static function applyStyle(styleData:TextStyleData, tf:TextField, textData:TextData = null):void
		{
			if(styleData)
			{
				var textFormat:TextFormat = tf.getTextFormat();
				
				// Check to make sure they are defined, then apply them to the textformat
				if(styleData.alignment != null)
					textFormat.align = styleData.alignment;
				
				if(styleData.fontFamily != null && styleData.fontFamily != "")
					textFormat.font = styleData.fontFamily;
				
				if(!isNaN(styleData.color))
					textFormat.color = styleData.color;
				
				// if text data has size then use that instead of style
				if((textData != null) && (!isNaN(textData.size)) && (textData.size != 0))
					textFormat.size = textData.size;
				else if(!isNaN(styleData.size))
					textFormat.size = styleData.size;
				
				if(styleData.bold)
					textFormat.bold = styleData.bold;
				
				if(styleData.italic)
					textFormat.italic = styleData.italic;
				
				if(styleData.underline)
					textFormat.underline = styleData.underline;
				
				if(!isNaN(styleData.leading))
					textFormat.leading = styleData.leading;
				
				if(!isNaN(styleData.letterSpacing))
					textFormat.letterSpacing = styleData.letterSpacing;
				
				if(!isNaN(styleData.indent))
					textFormat.indent = styleData.indent;
				
				if(!isNaN(styleData.marginLeft))
					textFormat.leftMargin = styleData.marginLeft;
				
				if(!isNaN(styleData.marginRight))
					textFormat.rightMargin = styleData.marginRight;
				
				if(styleData.effectData && styleData.effectData.filters.length > 0 )
					tf.filters = styleData.effectData.filters;
	
				if(!isNaN(styleData.yPos))
					tf.y = styleData.yPos;
				
				// set the textformat to the textfield
				tf.setTextFormat(textFormat);
				tf.defaultTextFormat = textFormat;
				tf.embedFonts = true;
				
				// lastly vertical align the textfield if the style data asks for it
				if(styleData.verticalAlign)
					verticalAlignTextField(tf);
				
				// needs to be last
				if(styleData.hasShadow)
				{
					addShadow(tf, styleData.shadow["alpha"], styleData.shadow["color"], styleData.shadow["offsetX"], styleData.shadow["offsetY"]);
				}
			}
			else
			{
				if(tf) trace("STYLE DATA WAS NULL: " + tf.name);
				else trace("STYLE DATA WAS NULL");
			}
		}
	}
}