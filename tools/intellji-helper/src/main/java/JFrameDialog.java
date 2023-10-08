import come.autoroute.helper.autoroutehelper.listeners.DialogDismissListener;
import come.autoroute.helper.autoroutehelper.models.FlatRouteItem;
import come.autoroute.helper.autoroutehelper.models.RoutePageInfo;
import come.autoroute.helper.autoroutehelper.models.RouterConfig;
import come.autoroute.helper.autoroutehelper.models.RoutesList;
import come.autoroute.helper.autoroutehelper.services.SettingsService;
import come.autoroute.helper.autoroutehelper.utils.Utils;
import org.apache.commons.lang.WordUtils;
import org.jetbrains.annotations.Nullable;

import javax.swing.*;
import javax.swing.plaf.basic.BasicComboBoxRenderer;
import java.awt.*;
import java.awt.event.KeyEvent;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;
import java.util.ArrayList;


public class JFrameDialog extends JDialog {
    private static final String runBuildRunnerKey = "arh-runBuildRunnerOnSave";
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
    public JTextField fileNameField;
    private JLabel fileNameLabel;
    private JCheckBox runBuildRunnerCheckBox;
    public ArrayList<FlatRouteItem> routeItems;
    final DialogDismissListener listener;
    public final RouterConfig router;

    public JFrameDialog(RouterConfig router, RoutesList routes, @Nullable RoutePageInfo pageInfo, SettingsService settingsService, DialogDismissListener listener) {
        this.listener = listener;
        this.router = router;
        this.routeItems = routes.flatten(1);
        setContentPane(contentPane);
        setModal(true);
        setTitle("Route info");
        getRootPane().setDefaultButton(buttonOK);
        targetListCombo.setRenderer(new ItemRenderer());
        targetListCombo.addItem("Root");
        if (pageInfo != null) {
            routeNameTextField.setText(router.getRouteName(pageInfo));
            routeNameTextField.setEnabled(pageInfo.getCustomName() == null);
            fileNameLabel.setVisible(false);
            fileNameField.setVisible(false);
        } else {
            fileNameField.getDocument().addDocumentListener((SimpleDocumentListener) e -> {
                String pascalCaseName = resolveClassName();
                if (pascalCaseName == null) return;
                final String suggestedClassName = Utils.Companion.resolveRouteName(pascalCaseName, null, router.getReplaceInRouteName());
                routeNameTextField.setText(suggestedClassName);
            });
        }
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

        runBuildRunnerCheckBox.setSelected(settingsService.getRunBuildRunnerOnSave());

        runBuildRunnerCheckBox.addChangeListener(e -> {
            final boolean selected = runBuildRunnerCheckBox.isSelected();
            settingsService.setRunBuildRunnerOnSave(selected);
        });


        // call onCancel() on ESCAPE
        contentPane.registerKeyboardAction(e -> onCancel(), KeyStroke.getKeyStroke(KeyEvent.VK_ESCAPE, 0), JComponent.WHEN_ANCESTOR_OF_FOCUSED_COMPONENT);


    }

    public static JFrameDialog show(RouterConfig router, RoutesList routes, RoutePageInfo pageInfo, @Nullable JComponent component, SettingsService settingsService, DialogDismissListener listener) {
        JFrameDialog dialog = new JFrameDialog(router, routes, pageInfo, settingsService, listener);

        dialog.pack();
        if (component != null) {
            dialog.setLocationRelativeTo(component);
        }
        dialog.setVisible(true);
        return dialog;
    }

    private void onOK() {
        listener.onDone(this);
        dispose();
    }

    private void onCancel() {
        dispose();
    }

    @Nullable
    public String resolveClassName() {
        final String path = fileNameField.getText();
        final String[] segments = path.split("/");
        if (segments.length == 0) return null;
        final String lastSegment = segments[segments.length - 1].split("\\.")[0];
        StringBuilder pascalCaseName = new StringBuilder();
        for (String s : lastSegment.split("_")) {
            pascalCaseName.append(WordUtils.capitalize(s));
        }
        return pascalCaseName.toString();
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

