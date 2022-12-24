import come.autoroute.helper.autoroutehelper.listeners.DialogDismissListener;
import come.autoroute.helper.autoroutehelper.models.FlatRouteItem;
import come.autoroute.helper.autoroutehelper.models.RouterConfig;
import come.autoroute.helper.autoroutehelper.models.RoutesList;
import come.autoroute.helper.autoroutehelper.models.RoutePageInfo;
import org.jetbrains.annotations.NotNull;

import javax.swing.*;
import javax.swing.plaf.basic.BasicComboBoxRenderer;
import java.awt.*;
import java.awt.event.KeyEvent;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;
import java.util.ArrayList;


public class JFrameDialog extends JDialog {
    private JPanel contentPane;
    private JButton buttonOK;
    private JButton buttonCancel;
    public JTextField routeNameTextField;
    public JTextField pathTextField;
    public JCheckBox maintainStateCheckBox;
    public JCheckBox fullPathMatchCheckBox;
    public JCheckBox deferredWebOnlyCheckBox;
    public JCheckBox fullscreenDialogCheckBox;
    public JComboBox<String> targetListCombo;
    public ArrayList<FlatRouteItem> routeItems;
    final DialogDismissListener listener;

    public JFrameDialog(RouterConfig router, RoutesList routes, RoutePageInfo pageInfo, DialogDismissListener listener) {
        this.listener = listener;
        this.routeItems = routes.flatten(1);
        setContentPane(contentPane);
        setModal(true);
        setTitle("Route info");
        getRootPane().setDefaultButton(buttonOK);
        targetListCombo.setRenderer(new ItemRenderer());
        targetListCombo.addItem("Root");
        routeNameTextField.setText(router.getRouteName(pageInfo));
        routeNameTextField.setEnabled(pageInfo.getCustomName() == null);
        for (final FlatRouteItem item : routeItems) {
            targetListCombo.addItem(new String(new char[item.getDept()]).replace("\0", "  ") + item.getRoute().getName());
        }

        targetListCombo.setSelectedIndex(0);
        buttonOK.addActionListener(e -> onOK());
        buttonCancel.addActionListener(e -> onCancel());

        // call onCancel() when cross is clicked
        setDefaultCloseOperation(DO_NOTHING_ON_CLOSE);
        addWindowListener(new WindowAdapter() {
            public void windowClosing(WindowEvent e) {
                onCancel();
            }
        });

        // call onCancel() on ESCAPE
        contentPane.registerKeyboardAction(e -> onCancel(), KeyStroke.getKeyStroke(KeyEvent.VK_ESCAPE, 0), JComponent.WHEN_ANCESTOR_OF_FOCUSED_COMPONENT);

    }

    private void onOK() {
        listener.onDone(this);
        dispose();
    }

    private void onCancel() {
        dispose();
    }

    public static JFrameDialog show(RouterConfig router, RoutesList routes, RoutePageInfo pageInfo, @NotNull JComponent component, DialogDismissListener listener) {
        JFrameDialog dialog = new JFrameDialog(router, routes, pageInfo, listener);
        dialog.pack();
        dialog.setLocationRelativeTo(component);
        dialog.setVisible(true);
        return dialog;
    }
}


class ItemRenderer extends BasicComboBoxRenderer {
    public Component getListCellRendererComponent(JList list, Object value, int index, boolean isSelected, boolean cellHasFocus) {
        super.getListCellRendererComponent(list, value, index, isSelected, cellHasFocus);
        if (index == -1) {
            setText("Add to " + value.toString().trim());
        }
        return this;
    }
}

