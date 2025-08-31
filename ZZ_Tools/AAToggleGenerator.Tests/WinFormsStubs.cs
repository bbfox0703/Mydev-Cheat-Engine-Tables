using System;
using System.Collections;
using System.Collections.Generic;
using System.Drawing;

namespace System.Windows.Forms
{
    public class Control
    {
        public Color BackColor { get; set; }
        public Color ForeColor { get; set; }
        public ControlCollection Controls { get; }
        public bool HasChildren => Controls.Count > 0;

        public Control()
        {
            Controls = new ControlCollection(this);
        }

        public class ControlCollection : IEnumerable<Control>
        {
            private readonly List<Control> _controls = new();

            public ControlCollection(Control owner) { }

            public void Add(Control control) => _controls.Add(control);

            public int Count => _controls.Count;

            public IEnumerator<Control> GetEnumerator() => _controls.GetEnumerator();

            IEnumerator IEnumerable.GetEnumerator() => _controls.GetEnumerator();
        }
    }

    public class Form : Control
    {
        public bool IsHandleCreated { get; set; }
        public IntPtr Handle { get; set; }
        public event EventHandler? HandleCreated;
    }

    public class Button : Control
    {
        public FlatStyle FlatStyle { get; set; }
        public FlatAppearance FlatAppearance { get; } = new();
    }

    public class FlatAppearance
    {
        public Color BorderColor { get; set; }
        public int BorderSize { get; set; }
        public Color MouseOverBackColor { get; set; }
        public Color MouseDownBackColor { get; set; }
    }

    public enum FlatStyle
    {
        Flat
    }

    public class Label : Control { }

    public class NumericUpDown : Control
    {
        public BorderStyle BorderStyle { get; set; }
    }

    public enum BorderStyle
    {
        FixedSingle
    }

    public class TreeView : Control
    {
        public List<TreeNode> Nodes { get; } = new();
        public Color LineColor { get; set; }
        public BorderStyle BorderStyle { get; set; }
    }

    public class TreeNode
    {
        public TreeNode(string? text = null) { }

        public Color ForeColor { get; set; }
    }
}

namespace ScintillaNET
{
    using System.Windows.Forms;

    public class Scintilla : Control
    {
        public StyleCollection Styles { get; } = new();
        public Color CaretForeColor { get; set; }
        public void SetSelectionBackColor(bool use, Color color) { }
    }

    public class StyleCollection
    {
        private readonly Dictionary<int, Style> _styles = new();

        public Style this[int index]
        {
            get
            {
                if (!_styles.TryGetValue(index, out var style))
                {
                    style = new Style();
                    _styles[index] = style;
                }
                return style;
            }
        }
    }

    public class Style
    {
        public Color BackColor { get; set; }
        public Color ForeColor { get; set; }

        public const int Default = 0;

        public static class Lua
        {
            public const int Default = 1;
            public const int Comment = 2;
            public const int CommentLine = 3;
            public const int CommentDoc = 4;
            public const int Number = 5;
            public const int Word = 6;
            public const int String = 7;
            public const int Character = 8;
            public const int LiteralString = 9;
            public const int Preprocessor = 10;
            public const int Operator = 11;
            public const int Identifier = 12;
        }
    }
}

