package game.systems.ui
{

	import flash.display.Sprite;
	import flash.geom.Rectangle;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import game.components.ui.TextDisplay;
	import game.nodes.ui.TextDisplayNode;
	import game.util.EntityUtils;
	import game.util.StringUtil;
	
	/**
	 * Manages a textual display that players can input to.
	 * To add text to the input, add text to the the TextDisplay's queue variable.
	 * To delete increment the TextDisplay's _deletes variable.
	 * NOTE :: Does not currently allow for changes to input placement, input is always added to end.
	 * TODO :: Need to add text wrapping functionality
	 */
	public class TextDisplaySystem extends System
	{
		
		override public function addToEngine( game : Engine ) : void
		{
			_nodes = game.getNodeList(TextDisplayNode);
			_game = game;
		}

		override public function update( time : Number ) : void
		{
			var node : TextDisplayNode;
			
			for ( node = _nodes.head; node; node = node.next )
			{
				if (EntityUtils.sleeping(node.entity))
				{
					continue;
				}
				updateNode(node);
			}
		}
		
		/**
		 * updates text dispaly and caret position and blinking
		 * @param	node
		 */
		private function updateNode(node:TextDisplayNode):void
		{
			var textDisplay:TextDisplay = node.textDisplay;
			
			// update caret
			if ( textDisplay.hasCaret )
			{
				if ( !textDisplay._caret )
				{
					createCaret( node );
				}
				
				if ( textDisplay.isCaretBlink )
				{
					updateCaretBlink( node );
				}
			}
			
			if ( textDisplay._clear )
			{
				textDisplay.tf.text = "";
				textDisplay._lines.length = 0;
				textDisplay._lines.push( "" );
				textDisplay._lineIndex = 0;
				textDisplay._deletes = 0;
				textDisplay.queue = "";
				textDisplay._clear = false;
			}

			//update _deletes 
			if ( textDisplay._deletes > 0 )
			{
				while ( textDisplay._deletes > 0 )
				{
					if ( textDisplay.queue.length > 0 )
					{
						textDisplay.queue = StringUtil.removeLast( textDisplay.queue );
					}
					else
					{
						textDisplay._lines[textDisplay._lineIndex] = StringUtil.removeLast( textDisplay._lines[textDisplay._lineIndex] );
						textDisplay.tf.text = StringUtil.removeLast( textDisplay.tf.text );
						
						if ( textDisplay._lines[textDisplay._lineIndex].length == 0 )
						{
							removeLine( textDisplay, textDisplay._lineIndex );
							textDisplay._lineIndex = ( textDisplay._lineIndex > 0 ) ? (textDisplay._lineIndex - 1) : 0;
						}
						updateCaretPosition( textDisplay );
						textDisplay._isFull = false;
					}
					textDisplay._deletes--;
				}
			}

			// update text addition from queuegg
			if ( textDisplay.queue.length > 0 )
			{
				// add chars from queue
				if ( textDisplay.delay > 0 )
				{
					textDisplay._duration--;
					if ( textDisplay._duration <= 0 )
					{
						if( !checkForNewLine(textDisplay) )
						{
							writeNextChar( textDisplay );
						}
						textDisplay._duration = textDisplay.delay;
					}
				}
				else
				{
					while ( textDisplay.queue.length > 0 )
					{
						if( !checkForNewLine(textDisplay) )
						{
							writeNextChar( textDisplay );
						}
					}
				}
			}
		}
		
		/**
		 * Adds first char in queue & calls for caret position update.
		 * Checks to see if char addition causes a line wrap & creates a new line if true.
		 * Adds char to current line, adds to TextField.text.
		 * Calls for update to caret position.
		 * @param	textDisplay
		 */
		private function writeNextChar ( textDisplay:TextDisplay ): void 
		{
			// get char and add to textField
			if ( !textDisplay._isFull )
			{
				var char:String = textDisplay.queue.charAt(0);
				textDisplay.tf.text += char;
				
				// check for word wrap
				var charLineIndex:int = textDisplay.tf.getLineIndexOfChar( textDisplay.tf.text.length - 1 );
				if ( charLineIndex != textDisplay._lineIndex )
				{
					textDisplay.tf.text = StringUtil.removeLast(textDisplay.tf.text);
					textDisplay._isFull = !addLine( textDisplay );
					writeNextChar ( textDisplay );
					return;
				}
	
				textDisplay._lines[ textDisplay._lineIndex ] += char;
				textDisplay.tf.setSelection(textDisplay.tf.text.length, textDisplay.tf.text.length);	// set carat
				
				if ( textDisplay.hasCaret )
				{
					textDisplay._caret.visible = true;
				}
			}
			textDisplay.queue = StringUtil.removeFirst( textDisplay.queue );
			
			//update caret position
			if ( textDisplay.hasCaret )
			{
				updateCaretPosition( textDisplay );;
			}
		}
		
		/////////////////////////////////////////////////////////////////
		///////////////////////////// LINES /////////////////////////////
		/////////////////////////////////////////////////////////////////
		
		/**
		 * Check to for new lines and add a new line if either is true.
		 * Checks for a new line comment in queue, then checks to see if line's length is over max.
		 * Returns true if new line comment was found, false otherwise.
		 * @param	textDisplay
		 * @return
		 */
		private function checkForNewLine ( textDisplay:TextDisplay ): Boolean 
		{
			// look for newline substring within queue
			if( textDisplay.queue.length > 1 && textDisplay.queue.substr(0,1) == StringUtil.NEW_LINE )
			{
				textDisplay.queue = textDisplay.queue.substring( 1 )
				if ( !addLine( textDisplay ))	
				{
					textDisplay.queue = "";		// if line max is reached form a new line, clear queue
				}
				return true;
			}
			else if ( textDisplay.lineCharMax > 0 )
			{
				// first line doesn't have a new line comment, so account for 2 chars
				var lineCharLength:int = ( textDisplay._lineIndex == 0 ) ? textDisplay._lines[ textDisplay._lineIndex ].length - 2 : textDisplay._lines[ textDisplay._lineIndex ].length;
				if ( lineCharLength == textDisplay.lineCharMax )
				{
					textDisplay._isFull = !addLine( textDisplay )
				}
			}
			return false;
		}
		
		/**
		 * Adds a new line if permitted, otherwise set _isFull flag to true.
		 * @param	textDisplay
		 */
		private function addLine ( textDisplay:TextDisplay ): Boolean 
		{
			// check lineMax, if set
			//if ( !textDisplay._isFull )
			//{
			var lineAdded:Boolean = false;

			if ( (textDisplay.lineMax > 0) && (textDisplay._lines.length + 1 > textDisplay.lineMax ) )
			{
				if ( textDisplay.lineScroll )	// delete first line, to make room for new line
				{
					removeLine( textDisplay, 0 );
					textDisplay._lines.push( "" );
					textDisplay.tf.text += StringUtil.NEW_LINE;
					lineAdded = true;
				}
			}
			else
			{
				textDisplay._lines.push( "" );
				textDisplay.tf.text += StringUtil.NEW_LINE;
				lineAdded = true;
			}
			textDisplay._lineIndex = textDisplay._lines.length - 1;
			return lineAdded;
			//}
		}
		
		/**
		 * Remove line at index.
		 * Calls for readjustment of text display to reflect deleted line.
		 * @param	textDisplay
		 * @param	index
		 */
		private function removeLine ( textDisplay:TextDisplay, index:int = -1 ): void 
		{
			if ( index == -1 )
			{
				index = textDisplay._lineIndex;
			}
			textDisplay._lines.splice( index, 1 );
			reapplyLines( textDisplay );
		}
		
		/**
		 * Refreshes text display to match current lines.
		 * @param	textDisplay
		 */
		private function reapplyLines( textDisplay:TextDisplay ):void
		{
			textDisplay.tf.text = "";
			
			for ( var i:int = 0; i < textDisplay._lines.length; i++ )
			{
				textDisplay.tf.text += textDisplay._lines[i];
				if ( textDisplay._lines.length != ( i + 1 ) )
				{
					textDisplay.tf.text += StringUtil.NEW_LINE;
				}
			}
		}
		
		/////////////////////////////////////////////////////////////////
		///////////////////////////// CARET /////////////////////////////
		/////////////////////////////////////////////////////////////////
		
		private function updateCaretBlink( node:TextDisplayNode ):void
		{
			node.textDisplay._caretCounter--;
			if ( node.textDisplay._caretCounter < 0 )
			{
				node.textDisplay._caret.visible = ( node.textDisplay._caret.visible ) ? false : true;
				node.textDisplay._caretCounter = node.textDisplay.caretDelay;
			}
		}
		
		private function updateCaretPosition( textDisplay:TextDisplay ):void
		{
			if ( textDisplay.hasCaret )
			{
				var rect:Rectangle = textDisplay.tf.getCharBoundaries( textDisplay.tf.length - 1);
				textDisplay._caret.x = Math.ceil(textDisplay.tf.x + rect.right);
				textDisplay._caret.y = Math.ceil(textDisplay.tf.y + rect.top);
			}
		}
		
		private function createCaret( node:TextDisplayNode ) : void
		{
				node.textDisplay._caret = new Sprite();
				node.display.displayObject.addChild( node.textDisplay._caret );
	
				node.textDisplay._caret.graphics.beginFill( Number(node.textDisplay.tf.defaultTextFormat.color) );
				
				// Method using text bounds
				node.textDisplay.tf.text += "|";
				var rect:Rectangle = node.textDisplay.tf.getCharBoundaries( 0 );
				node.textDisplay._caret.graphics.drawRect(0, 0, rect.width/2, rect.height );
				node.textDisplay.tf.text = StringUtil.removeLast(node.textDisplay.tf.text);
				
				// Method using text size
				/*
				var size:int = Math.floor( Number(node.textDisplay.tf.defaultTextFormat.size) );
				node.textDisplay._caret.graphics.drawRect(0, 0, Math.floor(size/6), size );
				*/
				
				node.textDisplay._caret.graphics.endFill();
		}
		
		override public function removeFromEngine( game : Engine ) : void
		{
			game.releaseNodeList( TextDisplayNode );
			_nodes = null;
		}
		
		private var _nodes:NodeList;
		private var _game:Engine;
		
		private static const CURSOR_BLINK_WAIT:uint = 100;
		private var CURSOR_BLINK_WAIT:uint = 100;
		
	}
}
